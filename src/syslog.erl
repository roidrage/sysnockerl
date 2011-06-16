-module(syslog).
-export([start_server/0, client/1, store/1]).

start_server() ->
    spawn(fun() -> server(4000) end).

server(Port) ->
    {ok, Socket} = gen_udp:open(Port, [binary]),
    io:format("server opened socket:~p~n",[Socket]),
    loop(Socket).

loop(Socket) ->
    receive
        {udp, Socket, Host, Port, Bin} = Msg ->
            io:format("server received:~p~n",[Msg]),
            N = binary_to_list(Bin),
            spawn(?MODULE, store, [N]),
            io:format("message: ~s~n", [N]),
            gen_udp:send(Socket, Host, Port, list_to_binary("ack")),
            loop(Socket);
        _ ->
           io:format("no match~n")
    end.

store(Message) ->
  io:format("~s~n", [Message]).

client(N) ->
    {ok, Socket} = gen_udp:open(0, [binary]),
    io:format("client opened socket=~p~n",[Socket]),
    ok = gen_udp:send(Socket, "localhost", 4000,
                     list_to_binary(N)),
    Value = receive
                {udp, Socket, _, _, Bin} = Msg ->
                    io:format("client received:~p~n",[Msg]),
                    binary_to_list(Bin)
            after 2000 ->
                    0
            end,
    gen_udp:close(Socket),
    Value.

