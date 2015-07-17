%% coding: latin-1
%%%-------------------------------------------------------------------
%%% @author Amershan
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. júl. 2015 12:15
%%%-------------------------------------------------------------------
-module(keystore).
-author("Amershan").

%% API
-compile(export_all).

-define(TcpPort, 9000).
-define(UDPPort, 4000).
-define(HttpPort, 8080).

start_server() ->
  Pid = spawn_link(fun() ->
    link(spawn(fun () ->
      tcp_server:start_server(?TcpPort)
      end)),
    link(spawn(fun () ->
      udp_server:start_server(?UDPPort)
      end)),
    link(spawn(fun () ->
      http_server:start(?HttpPort)
    end))
  end),
  {ok, Pid},
  ets:new(keystore, [named_table, ordered_set, public]).

storeKey(Key, Value) ->
ets:insert_new(keystore, {Key, Value}).

getData(Type, Key) ->
  Message = if
              (Type =:= "http") ->
                Result = lists:flatten(ets:lookup(keystore, Key)),
                Result;
              true ->
                Result = lists:flatten(ets:lookup(keystore, Key)),
                TempList = [ {X,list_to_binary(Y)} || {X,Y} <- Result ],
                JSON = mochijson2:encode(TempList),
                JSON
            end,
  Message.


getAllData(Type) ->
  Message = if
              (Type =:= "http") ->
                Result = lists:flatten(ets:match(keystore, '$1')),
                Result;
              true ->
                Result = lists:flatten(ets:match(keystore, '$1')),
                TempList = [ {X,list_to_binary(Y)} || {X,Y} <- Result ],
                JSON = mochijson2:encode(TempList),
                JSON

            end,
  Message.
