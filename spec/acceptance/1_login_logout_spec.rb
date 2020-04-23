require_relative "acceptance_helper.rb"

class LoginLogoutSpec < Minitest::Spec
    include ::Capybara::DSL
    include ::Capybara::Minitest::Assertions

    def self.test_order()
        :alpha
    end

    before do
        visit '/'
    end

    after do
        Capybara.reset_sessions!
    end

    it 'login and logout' do
        click_link("Login")
        sleep(0.5)

        within("#login-form") do
            fill_in('username', with: "user1")
            fill_in('password', with: "password1")
            click_button('login')
        end
        sleep(0.5)

        _(page).must_have_content('Logged in as user1')

        click_button('logout')
        sleep(0.5)

        _(page).must_have_content('Login')
    end


end