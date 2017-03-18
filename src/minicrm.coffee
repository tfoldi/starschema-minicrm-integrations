request = require 'request'
crmauth = require './minicrm-secret.json'

projects_url = "https://r3.minicrm.hu/Api/R3/Project\?Deleted\=0"
todolist_url = "https://r3.minicrm.hu/Api/R3/ToDoList/"



get = (url, callback) ->
  request url, crmauth,  (error, response, body) ->
    if error
      console.log "Error during MiniCRM API access", error
      return
    callback( JSON.parse body )


exports.getAllCrmTodo = (userid,callback) ->
  get projects_url, (body) ->
    Object.keys( body.Results ).forEach (project_id) ->
      console.log "project id=#{project_id}"#, name=#{project.Name}"
      get "#{todolist_url}#{project_id}?UserId=#{userid}", (todo_body) ->
        project = body.Results[project_id]
        console.log "project id=#{project_id}, name=#{project.Name}"
        callback(project,todo_body.Results)

