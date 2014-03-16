
type TSimpleServer <: TServer
    srvr_t::TServerTransport
    processor::TProcessor
    in_t::Function
    in_p::Function
    out_t::Function
    out_p::Function
end

function serve(s::TSimpleServer)
    listen(s.srvr_t)

    while true
        client = accept(s.srvr_t)
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
end

