require_relative "./rack_helper.rb"

describe "Photo Tagger API" do
  describe "Access Control" do
    before(:each) do
      @user1 = User.create(:google_id => "111111111")
      @user2 = User.create(:google_id => "222222222")
    end
    
    context "with empty session" do
      describe "GET /api/user/:user/photo/list" do
        it "errors out with 'me' as user" do
          get "/api/user/me/photo/list"
          expect(last_response.status).to eq 401
          expect(last_response.content_type).to eq "application/json"
          
          expect(JSON.parse(last_response.body)).to include(
                                                      "status" => "error",
                                                      "reason" => "no default user granted"
                                                    )
        end

        ["user1", "user2"].each do |name|
          it "denies access to #{name}" do
            get "/api/user/#{{"user1" => @user1, "user2" => @user2}[name].id}/photo/list"
            expect(last_response.status).to eq 401
            expect(last_response.content_type).to eq "application/json"
            
            expect(JSON.parse(last_response.body)).to include(
                                                        "status" => "error",
                                                        "reason" => "access denied"
                                                      )
          end
        end
      end
    end

    context "with cookie grant for user1" do
      describe "GET /api/whoami" do
        before(:each) do
          get "/api/whoami", {}, forge_session(:user_id => @user1.id)
        end

        it "responds with HTTP 200 OK" do
          expect(last_response.status).to eq 200
        end

        it "responds with application/json" do
          expect(last_response.content_type).to eq "application/json"
        end

        subject do JSON.parse(last_response.body) end

        it { should include(
                      "status" => "success",
                      "grant_type" => "CookieGrant",
                      "id" => @user1.id,
                      "google_id" => @user1.google_id
                    )}
      end

      describe "/api/user/:user/photo/list" do
        ["user1", "me"].each_with_index do |target, i|
          context "listing #{["user1's", "my"][i]} photos" do
            before(:each) do
              get "/api/user/#{[@user1.id, "me"][i]}/photo/list", {}, forge_session(:user_id => @user1.id)
            end

            it "should respond with HTTP 200 OK" do
              expect(last_response.status).to eq 200
            end

            it "should respond with application/json" do
              expect(last_response.content_type).to eq "application/json"
            end

            it "should have user1's id set in json" do
              json = JSON.parse(last_response.body)
              expect(json["owner"]).to eq @user1.id
            end
          end
        end
        context "listing user2's photos" do
          it "should raise AccessDeniedError" do
            get "/api/user/#{@user2.id}/photo/list", {}, forge_session(:user_id => @user1.id)
            expect(last_response.status).to eq 401
            expect(last_response.content_type).to eq "application/json"
            
            expect(JSON.parse(last_response.body)).to include(
                                                        "status" => "error",
                                                        "reason" => "access denied"
                                                      )
          end
        end
      end
    end
  end
end
