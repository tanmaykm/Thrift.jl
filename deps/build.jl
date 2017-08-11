using BinDeps
using Compat

@BinDeps.setup

bison = library_dependency("bison", aliases = ["bison"], os = :Darwin)
libtool = library_dependency("libtool", os = :Unix)
flex = library_dependency("flex", os = :Unix)
byacc = library_dependency("byacc", os = :Unix)

# Wrap in @osx_only to avoid non-OSX users from erroring out
@static if is_apple()
    using Homebrew
    provides(Homebrew.HB, "bison", bison, os = :Darwin )
end

provides(AptGet, Dict(# "bison" => bison,
                      "libtool" => libtool,
                      "flex" => flex,
                      "byacc" => byacc))


#Dict(:bison => :jl_bison)

try
    @BinDeps.install
end


# assuming script location is `PkgDir/deps`
const DEPS_DIR = dirname(@__FILE__)
const PKG_DIR = dirname(DEPS_DIR)
const DEPS_SRC = joinpath(DEPS_DIR, "src")
const DEPS_BIN = DEPS_DIR

# setup all install prefixes
const PREFIXES = Dict(
        "PY_PREFIX"=>DEPS_BIN,
        "JAVA_PREFIX"=>DEPS_BIN,
        "RUBY_PREFIX"=>DEPS_BIN,
        "PHP_PREFIX"=>DEPS_BIN,
        "PHP_CONFIG_PREFIX"=>DEPS_BIN,
        "PERL_PREFIX"=>DEPS_BIN,
        "ERLANG_INSTALL_LIB_DIR"=>DEPS_BIN
    )

for (n,v) in PREFIXES
    ENV[n] = v
end
const BUILD_ENV = isless(Base.VERSION, v"0.5.0-") ? ["$n=$v" for (n,v) in ENV] : ENV

const THRIFT_VERSION="0.9.3"
const THRIFT_GIT_SRC = "https://github.com/apache/thrift.git"
const THRIFT_SRC = joinpath(DEPS_SRC, "thrift-$THRIFT_VERSION")
const THRIFT_BUILD = [
        Cmd(`./bootstrap.sh`, dir="$THRIFT_SRC", env=BUILD_ENV),
        Cmd(`./configure --prefix=$DEPS_BIN --without-erlang --without-ruby`, dir="$THRIFT_SRC", env=BUILD_ENV),
        Cmd(`make install -j4`, dir="$THRIFT_SRC", env=BUILD_ENV)
    ]
const THRIFT_MKFILE = joinpath(THRIFT_SRC, "compiler", "cpp", "Makefile.am")
const JL_PLUGIN_SRC = joinpath(PKG_DIR, "compiler", "t_jl_generator.cc")
const JL_PLUGIN_DEST = joinpath(THRIFT_SRC, "compiler", "cpp", "src", "generate", "t_jl_generator.cc")

function ensure_dirs()
    isdir(DEPS_SRC) || mkdir(DEPS_SRC)
    isdir(DEPS_BIN) || mkdir(DEPS_BIN)
end

function patch_thrift()
    info("Moving julia plugin into thrift sources")
    cp(JL_PLUGIN_SRC, JL_PLUGIN_DEST, remove_destination=true)

    makefile = readstring(THRIFT_MKFILE)
    if searchindex(makefile, "t_jl_generator") == 0
        info("Patching thrift makefile")
        makefile = replace(makefile, "src/generate/t_lua_generator.cc", "src/generate/t_lua_generator.cc src/generate/t_jl_generator.cc")
        open(THRIFT_MKFILE, "w") do f
            write(f, makefile)
        end
    end
    nothing
end

function get_thrift()
    if !isdir(THRIFT_SRC)
        info("downloading thrift sources")
        run(`git clone -b $THRIFT_VERSION $THRIFT_GIT_SRC $THRIFT_SRC`)
    end
    #isfile(THRIFT_TAR_DEST) || download(THRIFT_TAR_SRC, THRIFT_TAR_DEST)
    #info("extracting thrift sources")
    #isdir(THRIFT_SRC) && rm(THRIFT_SRC; recursive=true)
    #run(`tar xzf $THRIFT_TAR_DEST -C $DEPS_SRC`)
end

function build_thrift()
    info("Buidling thrift compiler")
    for cmd in THRIFT_BUILD
        run(cmd)
    end
end

ensure_dirs()
get_thrift()
patch_thrift()
build_thrift()
