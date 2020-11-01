using Genie.Router
using CMSController

route("<path:full_url>", CMSController.cms_request)

route("/") do
  serve_static_file("welcome.html")
end