ActionController::Routing::Routes.draw do |map|
  map.root :controller => "example"
  map.connect ':controller/:action/:id'
end
