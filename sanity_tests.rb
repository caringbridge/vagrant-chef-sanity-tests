# X Does http://www.caringbridge.dev/ resolve?
# X Can you create an account?
# X Did you receive the welcome emails after creating your account?
# X Can you create a site 
# X Can you search for your site?
# Can you add a journal with a photo?
# Can you sign up for journal notifications?
# Did you receive a journal notification?
# Can you create a PDF of your site?
# Can you delete the photo from your journal?


require 'watir-webdriver'

@b = Watir::Browser.new :ff
@caringBridgeUrl = 'http://www.caringbridge.dev';
#@caringBridgeUrl = 'http://staging.caringbridge.org';

print "Does #{@caringBridgeUrl} resolve? \n"
@b.goto "#{@caringBridgeUrl}"

if @b.div(:id => 'dev-performance').when_present.text.include? "[DEV:Host centos6.caringbridge.dev]"
		print "Test passed!\n"
else
		print "Test failed!\n"
end

print "Can you create an account? \n"
@b.goto "#{@caringBridgeUrl}/signup"

testUserEmail = 'cbvagrantchef' + Time.now.to_i.to_s
puts "testUserEmail: #{testUserEmail}";
@b.text_field(:name => 'firstName').set 'Vagrant'
@b.text_field(:name => 'lastName').set 'Chef'
@b.text_field(:name => 'email').set testUserEmail + '@mailinator.com'
@b.text_field(:name => 'password').set '123456'
@b.checkbox(:name => 'terms', :value => '1').set
@b.button(:name => 'submit-btn').click

if @b.span(:class => 'user-generated global-profile-firstname').when_present.text == 'Vagrant'
		print "Test passed!\n"
else
		print "Test failed!\n"
end

print "Did you receive a welcome email? \n"
@b.goto 'http://mailinator.com/inbox.jsp?to=' + testUserEmail

if @b.div(:id => 'noemailmsg').exists?
		print "Test failed!\n" +
		"Emails can take up to 5 minutes to send. Consider waiting and rechecking inbox: http://mailinator.com/inbox.jsp?to=" + testUserEmail 
else
		print "Test passed!\n"
end

print "Can you start a site? \n"
@b.goto "#{@caringBridgeUrl}/createwebsite"

@b.checkbox(:name => 'terms', :value => '1').set
@b.text_field(:name => 'firstName').set 'Vagrant'
@b.text_field(:name => 'lastName').set 'Chef'
@b.text_field(:name => 'name').set 'Chef' + Time.now.to_i.to_s
@b.radio(:id => 'privacy-low', :value => 'low').set
@b.radio(:id => 'isSearchable', :value => '1').set
@b.button(:name => 'submit-btn').click

# @todo: Defaults to v3, when it defaults to v5 we can update this...
if @b.span(:class => 'user-generated global-profile-firstname').when_present.text == 'Vagrant'
		print "Test passed!\n"
else
		print "Test failed!\n"
end

# Fix inexplicable browser hang
# @todo: Fix inexplicable browser hang 
@b.close
@b = Watir::Browser.new :ff

print "Can you search for your site? \n"
@b.goto "#{@caringBridgeUrl}/search?q=Vagrant"

if @b.text.include? 'Is one of these the Site or SupportPlanner you are looking for?'
		print "Test passed!\n"
else
		print "Test failed!\n" +
		"Try running manually on Vagrant: sudo env APPLICATION_ENV=vagrant /opt/platform/scripts/cb search heartbeat\n" +
		"Still not working? vagrant destroy && vagrant up \n"
end

@b.close
@b = Watir::Browser.new :ff

print "\n *** Can you log in to your account? *** \n"
@b.goto "#{@caringBridgeUrl}/signin"
@b.text_field(:name => 'email').set testUserEmail + '@mailinator.com'
@b.text_field(:name => 'password').set '123456'
@b.checkbox(:name => 'remember-me').clear
@b.button(:name => 'submit-btn').click
@b.wait_until { @b.body.exists? }
  
if @b.text.include? 'Vagrant Chef'
    print "Test passed! Able to log in to account\n"
else
    print "Test failed! Unable to log in to account\n"
end

print "\n *** Can you create your first journal entry from the welcome page? *** \n"
@b.div(:class_name => 'site').link(:text => 'Vagrant Chef').click # Navigate to your caring bridge site
@b.wait_until { @b.body.exists? }
@b.text_field(:id => 'title').set 'My First Journal Title'
@b.iframe(:class_name => 'wysihtml5-sandbox').body.send_keys 'My first journal text'
@b.button(:name => 'submit-btn').click
@b.wait_until { @b.body.exists? }

if @b.text.include? 'My First Journal Title'
    print "Test passed creating first journal entry from welcome page\n"
else
    print "Test failed creating first journal entry from welcome page\n"
end

print "\n *** Can you add a journal entry with a photo? *** \n"
@b.link(:href => /journal/).click # Navigate to journal tab
@b.wait_until { @b.body.exists? }
@b.link(:id => 'bar-action-photo').click
@b.file_field(:id => 'photo-upload').set File.expand_path(File.dirname(__FILE__) + '/pig.jpg')
@b.text_field(:id => 'title').set 'Test journal with photo'
@b.iframe(:class_name => 'wysihtml5-sandbox').body.send_keys 'My journal text'
@b.button(:name => 'submit-btn').click

if @b.figure.div.present?
    print "Test passed creating journal entry with a photo\n"
else
    print "Test failed creating journal entry with a photo\n"
end

@b.close
