"""Bazel rules for ``.cppm`` C++ module interfaces and precompiled (BMI) modules.

* ``libcxx_std_module`` — precompiles libc++'s ``std`` module to ``std.pcm`` + ``std.o``
  with Clang (``import std;``). Default source path matches LLVM 22 under ``/usr/local``.
* ``cppm_interface`` — compiles one ``export module`` TU with ``-fmodule-output=``.
  Set ``std_pcm`` to a ``cppm_pcm_cc_dep`` wrapping ``std.pcm`` when the TU uses
  ``import std;`` (also pass ``-stdlib=libc++`` and link ``std.o`` on consumers).
* ``precompiled_libstdcxx_std_module`` — optional **GCC/g++** helper (``.gcm``); do not
  mix with the Clang + libc++ ``std.pcm`` path.
* ``cppm_select_outputs`` / ``cppm_pcm_cc_dep`` — split PCMs / expose as ``CcInfo`` deps.

Example (``import std`` in a ``.cppm``)::

    load("@bazel_skylib//rules:select_file.bzl", "select_file")
    load("//cpp:cppm.bzl", "cppm_interface", "cppm_pcm_cc_dep", "libcxx_std_module")

    libcxx_std_module(name = "libcxx_std")
    select_file(name = "libcxx_std_pcm", srcs = ":libcxx_std", subpath = "std.pcm")
    select_file(name = "libcxx_std_obj", srcs = ":libcxx_std", subpath = "std.o")
    cppm_pcm_cc_dep(name = "libcxx_std_pcm_dep", pcm = ":libcxx_std_pcm")

    cppm_interface(
        name = "demo_mod",
        src = "demo.cppm",
        module_name = "demo.math",
        std_pcm = ":libcxx_std_pcm_dep",
    )
"""

load("@bazel_skylib//rules:select_file.bzl", "select_file")
load("@rules_cc//cc:find_cc_toolchain.bzl", "CC_TOOLCHAIN_ATTRS", "find_cc_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

# Shared flags for Clang PCM generation so BMIs stay compatible across TUs.
_CLANG_PCM_BASE_COPTS = [
    "-U_FORTIFY_SOURCE",
    "-fstack-protector",
    "-Wall",
    "-fno-omit-frame-pointer",
    "-O3",
    "-fPIC",
    "-std=c++23",
]

CppmModuleInfo = provider(
    doc = "Built C++ module interface (PCM + object).",
    fields = {
        "pcm": "Precompiled module interface (LLVM BMI).",
        "object": "relocatable object for linking the module TU.",
        "module_name": "Logical module name (for -fmodule-file=NAME=path).",
    },
)

PrecompiledStdModuleInfo = provider(
    doc = "GCC libstdc++ precompiled ``std`` module artifacts.",
    fields = {
        "gcm": "Compiled module interface (.gcm).",
        "object": "Object file produced alongside the GCM (link when using ``import std``).",
    },
)

LibcxxStdModuleInfo = provider(
    doc = "Clang + libc++ precompiled ``std`` module (``std.pcm`` + ``std.o``).",
    fields = {
        "pcm": "Precompiled ``std`` BMI.",
        "object": "Object file for ``std`` (link with ``-stdlib=libc++``).",
    },
)

def _libcxx_std_module_impl(ctx):
    """Precompile ``/usr/local/share/libc++/v1/std.cppm`` (LLVM 22 layout) to ``std.pcm`` + ``std.o``."""
    cc_toolchain = find_cc_toolchain(ctx)
    compiler = cc_toolchain.compiler_executable
    pcm = ctx.actions.declare_file("std.pcm")
    obj = ctx.actions.declare_file("std.o")
    src = ctx.attr.libcxx_std_cppm
    args = _CLANG_PCM_BASE_COPTS + ctx.attr.copts + [
        "-stdlib=libc++",
        "-fmodule-output=" + pcm.path,
        "-c",
        src,
        "-o",
        obj.path,
    ]
    ctx.actions.run(
        outputs = [pcm, obj],
        inputs = depset(transitive = [cc_toolchain.all_files]),
        executable = compiler,
        arguments = args,
        mnemonic = "LibcxxStdModule",
        progress_message = "Precompiling libc++ module `std` to std.pcm",
    )
    return [
        DefaultInfo(files = depset([pcm, obj])),
        OutputGroupInfo(
            default = depset([pcm, obj]),
            pcm = depset([pcm]),
            object = depset([obj]),
        ),
        LibcxxStdModuleInfo(pcm = pcm, object = obj),
    ]

libcxx_std_module = rule(
    implementation = _libcxx_std_module_impl,
    attrs = dict(
        libcxx_std_cppm = attr.string(
            default = "/usr/local/share/libc++/v1/std.cppm",
            doc = "Absolute path to libc++ ``std.cppm`` (override if LLVM is installed elsewhere).",
        ),
        copts = attr.string_list(
            default = [],
            doc = "Extra flags for precompiling ``std`` (keep aligned with ``cppm_interface`` consumers).",
        ),
    ) | CC_TOOLCHAIN_ATTRS,
    toolchains = use_cc_toolchain(),
    fragments = ["cpp"],
    doc = "Build ``std.pcm`` and ``std.o`` from libc++ for ``import std;`` with Clang.",
)

def _precompiled_libstdcxx_std_module_impl(ctx):
    gcm = ctx.actions.declare_file(ctx.label.name + "/std.gcm")
    obj = ctx.actions.declare_file(ctx.label.name + "/std.o")
    ctx.actions.run_shell(
        mnemonic = "PrecompileLibstdcxxStd",
        progress_message = "Precompiling libstdc++ module `std` (GCC -fmodules)",
        outputs = [gcm, obj],
        command = (
            "set -euo pipefail\n"
            + "STD_CC=\"$$(ls /usr/include/c++/*/bits/std.cc 2>/dev/null | sort -V | tail -n1 || true)\"\n"
            + "if [ -z \"$${STD_CC}\" ] || [ ! -f \"$${STD_CC}\" ]; then\n"
            + "  echo >&2 \"precompiled_libstdcxx_std_module: need GCC libstdc++ headers (bits/std.cc).\"\n"
            + "  exit 1\n"
            + "fi\n"
            + "WORKDIR=\"$$(mktemp -d)\"\n"
            + "trap 'rm -rf \"$${WORKDIR}\"' EXIT\n"
            + "( cd \"$${WORKDIR}\" && g++ -std=c++23 -fmodules -c \"$${STD_CC}\" -o std.o )\n"
            + "cp -f \"$${WORKDIR}/std.o\" __OBJ__\n"
            + "cp -f \"$${WORKDIR}/gcm.cache/std.gcm\" __GCM__\n"
        ).replace("__OBJ__", obj.path).replace("__GCM__", gcm.path),
    )
    return [
        DefaultInfo(files = depset([gcm, obj])),
        OutputGroupInfo(
            default = depset([gcm, obj]),
            pcm = depset([gcm]),
            object = depset([obj]),
        ),
        PrecompiledStdModuleInfo(gcm = gcm, object = obj),
    ]

precompiled_libstdcxx_std_module = rule(
    implementation = _precompiled_libstdcxx_std_module_impl,
    attrs = {},
    doc = "Optional **GCC/g++** helper: precompile libstdc++ ``std`` for ``import std;``. Not used by the default Clang 22 build.",
)

def _cppm_interface_impl(ctx):
    cc_toolchain = find_cc_toolchain(ctx)
    compiler = cc_toolchain.compiler_executable
    cppm = ctx.file.src
    pcm = ctx.actions.declare_file(ctx.label.name + ".pcm")
    obj = ctx.actions.declare_file(ctx.label.name + ".o")

    args = list(_CLANG_PCM_BASE_COPTS) + ctx.attr.copts
    inputs = [cppm]
    transitive = [cc_toolchain.all_files]

    if ctx.attr.std_pcm:
        std_files = ctx.attr.std_pcm[DefaultInfo].files.to_list()
        if len(std_files) != 1:
            fail("std_pcm must be a cppm_pcm_cc_dep (or equivalent) exposing exactly one .pcm file")
        std_pcm = std_files[0]
        args = ["-stdlib=libc++"] + args
        args.append("-fmodule-file=std=" + std_pcm.path)
        inputs.append(std_pcm)

    for dep in ctx.attr.cppm_deps:
        info = dep[CppmModuleInfo]
        args.append("-fmodule-file={}={}".format(info.module_name, info.pcm.path))
        inputs.append(info.pcm)

    args += [
        "-fmodule-output=" + pcm.path,
        "-c",
        cppm.path,
        "-o",
        obj.path,
    ]

    ctx.actions.run(
        outputs = [pcm, obj],
        inputs = depset(inputs, transitive = transitive),
        executable = compiler,
        arguments = args,
        mnemonic = "CppmInterface",
        progress_message = "Compiling C++ module interface {}".format(ctx.attr.module_name),
    )

    return [
        DefaultInfo(files = depset([pcm, obj])),
        OutputGroupInfo(
            default = depset([pcm, obj]),
            pcm = depset([pcm]),
            object = depset([obj]),
        ),
        CppmModuleInfo(
            pcm = pcm,
            object = obj,
            module_name = ctx.attr.module_name,
        ),
    ]

cppm_interface = rule(
    implementation = _cppm_interface_impl,
    attrs = dict(
        src = attr.label(mandatory = True, allow_single_file = [".cppm"]),
        module_name = attr.string(
            mandatory = True,
            doc = "Module name as in `export module name;` (also used for `-fmodule-file=`).",
        ),
        copts = attr.string_list(default = []),
        std_pcm = attr.label(
            default = None,
            providers = [DefaultInfo],
            doc = "``cppm_pcm_cc_dep`` for prebuilt ``std.pcm`` when this TU contains ``import std;``.",
        ),
        cppm_deps = attr.label_list(
            default = [],
            providers = [CppmModuleInfo],
            doc = "Other `cppm_interface` targets this TU imports.",
        ),
    ) | CC_TOOLCHAIN_ATTRS,
    toolchains = use_cc_toolchain(),
    fragments = ["cpp"],
    doc = "Compile a `.cppm` interface to PCM + object (Clang `-fmodule-output`).",
)

def _cppm_pcm_cc_dep_impl(ctx):
    """Expose a ``.pcm`` as a ``CcInfo`` dep so ``cc_*`` compile actions get the file as an input."""
    pcm = ctx.file.pcm
    compilation_context = cc_common.create_compilation_context(
        headers = depset([pcm], order = "postorder"),
    )
    linking_context = cc_common.create_linking_context(linker_inputs = depset())
    return [
        DefaultInfo(files = depset([pcm])),
        CcInfo(
            compilation_context = compilation_context,
            linking_context = linking_context,
        ),
    ]

cppm_pcm_cc_dep = rule(
    implementation = _cppm_pcm_cc_dep_impl,
    attrs = {
        "pcm": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "Precompiled module (``*.pcm``) from ``cppm_select_outputs`` ``*_pcm``.",
        ),
    },
    doc = """Wrap a ``.pcm`` in ``CcInfo`` so ``cc_test`` / ``cc_binary`` can ``deps`` it and use
``$(execpath :this_target)`` in ``copts`` for ``-fmodule-file=`` (compile sandbox sees the file).""",
)

def cppm_select_outputs(name, cppm, stem):
    """Expose ``stem.pcm`` / ``stem.o`` as separate targets for ``$(execpath)`` / ``cc_import``.

    Args:
      name: prefix for generated ``select_file`` rules (``name + \"_pcm\"`` / ``_obj``).
      cppm: label of a ``cppm_interface`` target.
      stem: basename of declared outputs (same as the ``cppm_interface`` rule's ``name``).
    """
    select_file(
        name = name + "_pcm",
        srcs = cppm,
        subpath = stem + ".pcm",
    )
    select_file(
        name = name + "_obj",
        srcs = cppm,
        subpath = stem + ".o",
    )
