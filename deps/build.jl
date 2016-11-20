using BinDeps
@BinDeps.setup
bison = library_dependency("bison", aliases = ["bison"])
# Wrap in @osx_only to avoid non-OSX users from erroring out
@static if is_apple()
    using Homebrew
    provides( Homebrew.HB, "bison", bison, os = :Darwin )
end

#Dict(:bison => :jl_bison)
try
    @BinDeps.install
end

run(`pwd`)
THRIFT_VERSION="0.9.3"
THRIFT_PATH = "http://mirror.cc.columbia.edu/pub/software/apache/thrift/$THRIFT_VERSION/thrift-$THRIFT_VERSION.tar.gz"
thrifttar = "thrift.tar.gz"
jlgeneratorcpp = "../compiler/t_jl_generator.cc"
thriftgenerators = "thrift-$THRIFT_VERSION/compiler/cpp/src/generate/t_jl_generator.cc"
info("downloading thrift sources")
# download(THRIFT_PATH, thrifttar)
info("extracting thrift sources")
run(`tar xzf ./thrift.tar.gz -C ./`)
run(`ls thrift-$THRIFT_VERSION`)
info("Moving julia plugin into thrift sources")
cp(jlgeneratorcpp, thriftgenerators, remove_destination=true)

info("Buidling thrift compiler")
build = Cmd(`./configure`,
            dir="./thrift-$THRIFT_VERSION") &
        Cmd(`make -j4`,
            dir="./thrift-$THRIFT_VERSION")
run(build)
cp("./thrift-$THRIFT_VERSION/compiler/cpp/thrift", "./thrift", remove_destination=true)
chmod("./thrift", 0o744)
