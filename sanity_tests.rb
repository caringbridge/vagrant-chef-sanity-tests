require 'watir-webdriver'

@b = Watir::Browser.new :ff

# Does caringbridge.dev resolve?
@b.goto 'http://www.caringbridge.dev'
# @todo: check if page exists

# Can you create a profile?
@b.goto 'https://www.caringbridge.dev/signup'

@b.text_field(:name => 'firstName').set 'Vagrant'
@b.text_field(:name => 'lastName').set 'Chef'
@b.text_field(:name => 'email').set 'cbwandersen+vagrantchef' + Time.now.to_i.to_s + '@gmail.com'
@b.text_field(:name => 'password').set '123456'
@b.checkbox(:name => 'terms', :value => '1').set
@b.button(:name => 'submit-btn').click

if @b.span(:class => 'user-generated global-profile-firstname').when_present.text == 'Vagrant'
		print 'Test passed!'
else
		print 'Test failed!'
end
