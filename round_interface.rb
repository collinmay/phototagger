# called "round" cause there's a round trip involved

class TaggerApp < Sinatra::Base
  before "/app/round/*" do
    begin
      user
    rescue => e
      if e.is_a? NoDefaultUserGrantedError then
        redirect "/auth/google/userinfo"
      elsif e.is_a? AccessDeniedError then
        halt 401, haml(:round_access_denied, :format => :html5)
      else
        raise e
      end
    end
  end
  
  get "/app/round/" do
    haml :round_gallery, :format => :html5
  end

  get "/app/round/*" do
    status 404
    haml :round_not_found, :format => :html5
  end
end
