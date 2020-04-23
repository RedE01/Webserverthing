require_relative "acceptance_helper.rb"

class CreateUserSpec < Minitest::Spec
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

    it 'create user' do
        click_link("Register")
        sleep(0.5)

        fill_in('username', with: "newUser")
        fill_in('password', with: "newPassword")
        fill_in('passwordConfirm', with: "newPassword")
        click_button('Create user')
        sleep(0.5)

        _(page).must_have_content("login")

        within("#login-form") do
            fill_in('username', with: "newUser")
            fill_in('password', with: "newPassword")
            click_button('login')
        end
        sleep(0.5)

        _(page).must_have_content('Logged in as newUser')
    end


end