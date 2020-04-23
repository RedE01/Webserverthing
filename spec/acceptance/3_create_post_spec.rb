require_relative "acceptance_helper.rb"

class CreatePostSpec < Minitest::Spec
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

    it 'create post' do
        click_link("Login")
        sleep(0.5)

        _(page).must_have_content("login")

        within("#login-form") do
            fill_in('username', with: "user1")
            fill_in('password', with: "password1")
            click_button('login')
        end
        sleep(0.5)

        _(page).must_have_content('Logged in as user1')

        click_link('Create post')
        sleep(0.1)
        _(page).must_have_content('Create post')

        fill_in('title', with: "Testing Title")
        fill_in('content', with: "Testing content")
        # fill_in('content', with: "password1")
        click_button('Create post')
        sleep(0.5)

        _(page).must_have_content('Testing Title')

        click_link('Testing Title')
        sleep(0.5)

    end


end