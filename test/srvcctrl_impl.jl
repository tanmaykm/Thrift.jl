global srvr

function start_service(s)
    global srvr
    srvr = s
    serve(srvr)
end

function stop_service()
    global srvr
    close(srvr)
end
