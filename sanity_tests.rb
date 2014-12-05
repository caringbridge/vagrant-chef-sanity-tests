# X Does http://www.caringbridge.dev/ resolve?
# X Can you create an account?
# X Did you receive the welcome emails after creating your account?
# X Can you create a site 
# X Can you search for your site?
# X Can you add a journal with a photo?
# X Can you sign up for journal notifications?
# X Did you receive a journal notification?
# Can you create a PDF of your site?
# X Can you delete the photo from your journal?

require 'net/http'
require 'timeout'
require 'watir-webdriver'

# Very basic function to keep track of tests that have passed/failed
def verify (description, bool_expression)
    puts "\n*** #{description} ***"
    $test_count += 1
    if bool_expression
        puts "PASS: #{description}"
        $pass_count += 1
        return 1
    else
        puts "FAIL: #{description}"
        $fail_count += 1
        return 0
    end
end

# Iterates through an array of URLs and returns the the first one that
# can be resolved. Returns empty string if none of the URLs resolved.
def resolve_url url_array
    url_array.each do |url_str|
        url = URI.parse(url_str)
        req = Net::HTTP.new(url.host, url.port)

        begin
            Timeout.timeout(5) do
                res = req.request_head(url.path)

                if res.code == "200"
                    return url_str
                end
            end
        rescue Timeout::Error
            puts "URL #{url_str} did not respond in 5 seconds."
            next
        end
    end
    return ""
end

$test_count = 0
$pass_count = 0
$fail_count = 0

# Make sure each url ends with a '/'
url_array = [ 'http://www.caringbridge.dev/', 
              'http://staging.caringbridge.org/' ]

test_url = resolve_url url_array

if test_url == ""
    puts "Could not resolve any of the URLs. Exiting..."
    exit
end
puts "Using test url: #{test_url}"

@b = Watir::Browser.new :ff
time_in_secs_now = Time.now.to_i.to_s
user_email_base = 'cbvagrantchef' + time_in_secs_now
user_email = user_email_base + "@mailinator.com"
site_name_id =  'Chef' + time_in_secs_now
puts "user_email: #{user_email}"
puts "site_name_id: #{site_name_id}"

puts "Does #{test_url} resolve?"
@b.goto "#{test_url}"

verify("#{test_url} resolves", (@b.div(:id => 'dev-performance').when_present.text.include? "[DEV:Host centos6.caringbridge.dev]"))


puts "Can you create an account?"
@b.goto "#{test_url}signup"
@b.text_field(:name => 'firstName').set 'Vagrant'
@b.text_field(:name => 'lastName').set 'Chef'
@b.text_field(:name => 'email').set user_email
@b.text_field(:name => 'password').set '123456'
@b.checkbox(:name => 'terms', :value => '1').set
@b.button(:name => 'submit-btn').click

verify("Create an account", (@b.span(:class => 'user-generated global-profile-firstname').when_present.text == 'Vagrant'))


# Did user receive a welcome email?
@b.goto 'http://mailinator.com/inbox.jsp?to=' + user_email_base

result = verify("User received welcome email", !(@b.div(:id => 'noemailmsg').present?))
if result == 0
    puts "Emails can take up to 5 minutes to send. Consider waiting and rechecking inbox: http://mailinator.com/inbox.jsp?to=#{user_email_base}"
end


# Can you start a site?
@b.goto "#{test_url}createwebsite"
@b.checkbox(:name => 'terms', :value => '1').set
@b.text_field(:name => 'firstName').set 'Vagrant'
@b.text_field(:name => 'lastName').set 'Chef'
@b.text_field(:name => 'name').set site_name_id
@b.radio(:id => 'privacy-low', :value => 'low').set
@b.radio(:id => 'isSearchable', :value => '1').set
@b.button(:name => 'submit-btn').click


# @todo: Defaults to v3, when it defaults to v5 we can update this...
verify("Start a site", (@b.span(:class => 'user-generated global-profile-firstname').when_present.text == 'Vagrant'))

# Fix inexplicable browser hang
# @todo: Fix inexplicable browser hang 


# Can you create your first journal entry from the welcome page?
@b.text_field(:id => 'title').when_present.set 'My First Journal Title'
@b.iframe(:class_name => 'wysihtml5-sandbox').body.send_keys 'My first journal text'
@b.button(:name => 'submit-btn').click
@b.wait_until { @b.body.exists? }
verify("Create first journal entry from the welcome page", (@b.text.include? 'My First Journal Title'))

# Set notification preferences to immediate
@b.link(:class_name => 'btn btn-default choose-site-notifications btn-block').click 
@b.checkbox(:id => 'van-email').set
@b.checkbox(:id => 'van-sms').clear
@b.checkbox(:id => 'jen-email').set
@b.checkbox(:id => 'jen-sms').clear
@b.select_list(:id => 'notification-method').select_value('immediate')
@b.button(:text => /Save Changes/).click

# Can you send an invite?
invitee_email_base = 'cbinvitee' + time_in_secs_now
invitee_email = invitee_email_base + "@mailinator.com"
@b.goto "#{test_url}visit/#{site_name_id}/journal"
@b.link(:class_name => 'rhs-invite-link').click 
@b.text_field(:id => 'invite-addresses').set invitee_email
@b.button(:class_name => 'btn btn-primary pull-right primaryaction').click
@b.goto 'http://mailinator.com/inbox.jsp?to=' + invitee_email_base
@b.wait_until { @b.ul(:id => 'mailcontainer').lis.length == 1 }
verify("Invitee received welcome email", (@b.ul(:id => 'mailcontainer').lis.length == 1))

@b.close
@b = Watir::Browser.new :ff


# Invitee clicks subscribe to Vagrant's journal notifications
@b.goto "#{test_url}visit/#{site_name_id}"
@b.link(:class => 'btn btn-default choose-site-notifications btn-block').when_present.click
@b.checkbox(:id => 'jen-email').set
@b.button(:class_name => 'submit-modal btn btn-primary').click
verify("Invitee clicking subscribe goes to login page", (@b.url == "#{test_url}visit/#{site_name_id}"))


# Invitee creates login
@b.link(:class_name => 'btn btn-primary').when_present.click 
@b.text_field(:id => 'firstname').when_present.set 'Fred'
@b.text_field(:id => 'lastname').set 'Invitee'
@b.text_field(:id => 'email').set invitee_email
@b.text_field(:id => 'password').set '123456'
@b.checkbox(:id => 'login-ecomm').clear
@b.checkbox(:id => 'terms').set
@b.button(:id => 'submit-login-modal').click

@b.close
@b = Watir::Browser.new :ff


# Can you search for your site?
@b.goto "#{test_url}search?q=Vagrant"

result = verify("Search for your site", (@b.text.include? 'Is one of these the Site or SupportPlanner you are looking for?'))
if (result == 0)
    puts "Try running manually on Vagrant: sudo env APPLICATION_ENV=vagrant /opt/platform/scripts/cb search heartbeat\n" +
        "Still not working? vagrant destroy && vagrant up \n"
end


# Can you log in to your account?
@b.goto "#{test_url}signin"
@b.text_field(:name => 'email').when_present.set user_email
@b.text_field(:name => 'password').set '123456'
@b.checkbox(:name => 'remember-me').clear
@b.button(:name => 'submit-btn').click
@b.wait_until { @b.body.exists? }
verify("Log into account", (@b.text.include? 'Vagrant Chef'))


# Can you add a journal entry with a photo?
photo_file = File.expand_path(File.dirname(__FILE__) + '/pig.jpg')
if (!File.exist?(photo_file))
    verify("Can't test adding journal entry with photo. File #{photo_file} does not exist", false)
else
    @b.goto "#{test_url}visit/#{site_name_id}/journal/add" # Navigate to journal tab
    @b.wait_until { @b.body.exists? }
    @b.link(:id => 'bar-action-photo').click
    @b.file_field(:id => 'photo-upload').set photo_file
    @b.text_field(:id => 'title').set 'Test journal with photo'
    @b.iframe(:class_name => 'wysihtml5-sandbox').body.send_keys 'My journal text'
    @b.button(:name => 'submit-btn').click

    verify("Add journal entry with photo", @b.figure.div.present?)
end


# Did invitee recieve email for journal entry?
@b.goto 'http://mailinator.com/inbox.jsp?to=' + invitee_email_base
@b.wait_until { @b.ul(:id => 'mailcontainer').lis.length == 2 }
verify("Invitee received new journal entry email", (@b.ul(:id => 'mailcontainer').lis.length == 2))


# Can you delete a photo from a journal entry?
@b.goto "#{test_url}visit/#{site_name_id}/journal" # Navigate to journal tab
@b.wait_until { @b.body.exists? }
@b.link(:class_name => 'btn btn-default pull-right').click
@b.button(:class_name => 'pull-right btn btn-default btn-sm').when_present.click
@b.button(:id => 'submit-btn').click
verify("Delete photo from journal entry", !(@b.figure.div.present?))

@b.close

puts "\n*** TEST RESULTS ***"
puts "Total tests: #{$test_count}"
puts "PASS: #{$pass_count}"
puts "FAIL: #{$fail_count}"

