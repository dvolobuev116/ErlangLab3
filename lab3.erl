-module(lab3).
-export([server_loop/1, client_loop/2, connect/2, disconnect/2, send/3, spawn_server/0, spawn_client/2]).

exists([], _) -> false;
exists([User|_], User) -> true;
exists([H|T], User) -> exists(T, User).

put1(User, []) -> [User];
put1(User, [User | T]) -> [User | T];
put1(User, [H | T]) -> [H | put1(User, T)].

delete(User, Users) -> [X || X<- Users, X =:= User].

loop(Users) ->
	receive
		{users} -> 
			io:format("~p~n", [Users]),
			loop(Users);
		{connect, User} -> 
			Users1 = put1(User, Users),
			loop(Users1);
		{disconnect, User} -> 
			Users1 = delete(User, Users),
			loop(Users1);
		{send, Msg, User} ->
			Exists = exists(Users, User),
			if
				Exists -> io:format("~s says: ~s~n", [User, Msg]);
				true -> io:format("User not exists!~n")
			end,
			loop(Users)
	end.

connect(User, Server) ->
	Server ! {connect, User}.

disconnect(User, Server) ->
	Server ! {disconnect, User}.

send(Msg, User, Server) ->
	Server ! {send, Msg, User}.

%Client-Server

exists1([], _) -> false;
exists1([{User, _}|_], User) -> true;
exists1([{X, _}|T], User) -> exists1(T, User).

delete1(User, Users) -> [{U, Client} || {U, Client} <- Users, U =/= User].

server_send([], _) -> [];
server_send([{_, Client}|T], Msg) ->
	Client ! {print, Msg},
	server_send(T, Msg).

server_loop(Users) ->
	receive
		{users} -> 
			io:format("~p~n", [Users]),
			server_loop(Users);
		{connect, {User, Client}} -> 
			Exists = exists1(Users, User),
			if
				Exists -> 
					io:format("User with same name already connected!~n"),
					server_loop(Users);
				true -> 
					Users1 = put1({User, Client}, Users),
					io:format("~s connected.~n", [User]),
					server_loop(Users1)
			end;
		{disconnect, User} -> 
			Users1 = delete1(User, Users),
			io:format("~s disconnected.~n", [User]),
			server_loop(Users1);
		{send, Msg, User} ->
			Exists = exists1(Users, User),
			if
				Exists -> server_send(Users, io:format("~s says: ~s~n", [User, Msg]));
				true -> io:format("You are not authorized!~n")
			end,
			server_loop(Users)
	end.

client_loop(User, Server) ->
	receive
		{connect} ->
			Server ! {connect, {User, self()}},
			client_loop(User, Server);
		{disconnect} ->
			Server ! {disconnect, User};
		{send, Msg} ->
			Server ! {send, Msg, User},
			client_loop(User, Server);
		{print, Msg} ->
			io:format("~s~n", [Msg]),
			client_loop(User, Server)
	end.

spawn_server() ->
	spawn(lab3, server_loop, [[]]).

spawn_client(User, Server) ->
	spawn(lab3, client_loop, [User, Server]).