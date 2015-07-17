%%%-------------------------------------------------------------------
%%% @author Amershan
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. júl. 2015 16:22
%%%-------------------------------------------------------------------
-module(tcp_server).
-author("Amershan").

%% API
-export([start_server/1, sendMessage/2]).

start_server(Port) ->
  Pid = spawn_link(fun() ->
    {ok, LSocket} = gen_tcp:listen(Port, [binary, {active, false}]),
    io:format("TCP server listening on port: ~p ~n", [Port]),
    spawn(fun () -> acceptState(LSocket) end),
    timer:sleep(infinity)
  end),
  {ok, Pid}.

acceptState(LSocket) ->
  {ok, ASocket} = gen_tcp:accept(LSocket),
  spawn(fun() -> acceptState(LSocket) end),
  tcpHandler(ASocket).

tcpHandler(ASocket) ->
  inet:setopts(ASocket, [{active, once}]),

  receive
    {tcp, ASocket, <<"quit">>} ->
      gen_tcp:close(ASocket);
    {tcp, ASocket, BinaryMsg} ->
      ReceivedData = [binary_to_list(X) || X <- binary:split(BinaryMsg, [<<":::">>], [trim, global])],
      io:format("Server received: ~p ~n", [ReceivedData]),

      case lists:member("store", ReceivedData) of
        true  ->
          [_, Key, Value] = ReceivedData,
          keystore:storeKey(Key, Value),
          io:format("Data stored ~n"),
          gen_tcp:send(ASocket, "Data stored");
        false ->  case lists:member("getData", ReceivedData) of
                    true  ->
                      [_, Key] = ReceivedData,
                      Result = keystore:getData("tcp", Key),
                      gen_tcp:send(ASocket, Result);

                    false -> case lists:member("getAllData", ReceivedData) of
                               true ->
                                 Result = keystore:getAllData("tcp"),
                                 gen_tcp:send(ASocket, Result);
                               false ->
                                 gen_tcp:send(ASocket, "Command not supported")
                              end
                    end
      end,
      tcpHandler(ASocket)
  end.

sendMessage(Socket, Message) ->
  gen_tcp:send(Socket, Message).

