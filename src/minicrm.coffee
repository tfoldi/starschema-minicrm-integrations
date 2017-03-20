request = require 'request'
fp = require 'lodash/fp'
crmauth = require './minicrm-secret.json'

projects_url = "https://r3.minicrm.hu/Api/R3/Project\?Deleted\=0"
todolist_url = "https://r3.minicrm.hu/Api/R3/ToDoList/"



send_request = fp.curry (method, url, callback) ->
  method url, crmauth,  (error, response, body) ->
    return console.log "Error during MiniCRM API access", error if error
    callback( JSON.parse body )

get  = send_request request.get
post = send_request request.post


exports.getAllCrmTodo = (userid,callback) ->
  get projects_url, (body) ->
    Object.keys( body.Results ).forEach (project_id) ->
      get "#{todolist_url}#{project_id}?UserId=#{userid}", (todo_body) ->
        project = body.Results[project_id]
        callback(project,todo_body.Results)

