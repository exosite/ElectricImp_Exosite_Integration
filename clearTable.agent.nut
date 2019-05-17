

//Use this agent to clear the token from the server table.
// This can be used to help re-provision a device if the authentication gets out of sync

// General usage
// 1.) impt build run -y clearTable.agent.nut --dg <my_device_group>
// 2.) impt build run -y <my_agent>.agent.nut --dg <my_device_group>

server.log("Clearing token from server table");
local persist = server.load(); 
persist.rawdelete(exosite_token); 
local result = server.save(persist);
server.log("Result of save: " + result);
