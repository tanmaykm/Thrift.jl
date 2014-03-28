
type TServerBase
    srvr_t::TServerTransport
    processor::TProcessor
    in_t::Function
    in_p::Function
    out_t::Function
    out_p::Function
end

function serve_accepted(client::TTransport, s::TServerBase)
    itrans = s.in_t(client)
    otrans = s.out_t(client)
    iprot = s.in_p(itrans)
    oprot = s.out_p(otrans)

    try
        while true
            process(s.processor, iprot, oprot)
        end
    catch ex
        if !isa(ex, EOFError)
            println(ex)
            Base.error_show(STDERR, ex, catch_backtrace())
        end
    end
    close(itrans)
    close(otrans)
end

close(srvr::TServer) = close(srvr.base.srvr_t)

##
# Blocking server. Requests are processed in the main task.
type TSimpleServer <: TServer
    base::TServerBase
    TSimpleServer(srvr_t::TServerTransport, processor::TProcessor, in_t::Function, in_p::Function, out_t::Function, out_p::Function) = new(TServerBase(srvr_t, processor, in_t, in_p, out_t, out_p))
end

function serve(ss::TSimpleServer)
    s = ss.base
    listen(s.srvr_t)

    while true
        client = accept(s.srvr_t)
        serve_accepted(client, s)
    end
end



##
# Task server. Tasks are spawned for each connection.
type TTaskServer <: TServer
    base::TServerBase
    TTaskServer(srvr_t::TServerTransport, processor::TProcessor, in_t::Function, in_p::Function, out_t::Function, out_p::Function) = new(TServerBase(srvr_t, processor, in_t, in_p, out_t, out_p))
end

##
# Process Pool Server
type TProcessPoolServer <: TServer
    base::TServerBase
    function TProcessPoolServer(srvr_t::TServerTransport, processor::TProcessor, in_t::Function, in_p::Function, out_t::Function, out_p::Function) 
        distribute(processor)
        new(TServerBase(srvr_t, processor, in_t, in_p, out_t, out_p))
    end
end

typealias TAsyncServer  Union(TTaskServer, TProcessPoolServer)

function serve(ss::TAsyncServer)
    s = ss.base
    listen(s.srvr_t)

    while true
        client = accept(s.srvr_t)
        @async serve_accepted(client, s)
    end
end

