require 'uri'
require 'cgi'

require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "paths"))
require File.expand_path(File.join(File.dirname(__FILE__), "..", "support", "selectors"))

module WithinHelpers
  def with_scope(locator)
    locator ? within(*selector_for(locator)) { yield } : yield
  end
end
World(WithinHelpers)

# Single-line step scoper
When /^(.*) within ([^:]+)$/ do |step_def, parent|
  with_scope(parent) { step step_def }
end

# Multi-line step scoper
When /^(.*) within ([^:]+):$/ do |step_def, parent, table_or_string|
  with_scope(parent) { step "#{step_def}:", table_or_string }
end

Given /^(?:|I )am on (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )go to (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^(?:|I )follow "([^"]*)"$/ do |link|
  click_link(link)
end
Then /^I should be redirected to (.+)$/ do |page|
  puts 'TODO: make this done'
  step "I should be on #{page}"
end

Then /^(?:|I )should see "([^"]*)"$/ do |text|
  if page.respond_to? :should
    expect(page).to have_content(text)
  else
    assert page.has_content?(text)
  end
end
Then /^(?:|I )should not see "([^"]*)"$/ do |text|
  if page.respond_to? :should
    page.should have_no_content(text)
  else
    assert page.has_no_content?(text)
  end
end

Then /^(?:|I )should see \/([^\/]*)\/([imxo])?$/ do |regexp,flags|
  regexp_opts = [regexp,flags].compact
  regexp = Regexp.new(*regexp_opts)

  if page.respond_to? :should
    page.should have_xpath('//*', :text => regexp)
  else
    assert page.has_xpath?('//*', :text => regexp)
  end
end

Then /^(?:|I )should not see \/([^\/]*)\/([imxo])?$/ do |regexp,flags|
  regexp_opts = [regexp,flags].compact
  regexp = Regexp.new(*regexp_opts)

  if page.respond_to? :should
    page.should have_no_xpath('//*', :text => regexp)
  else
    assert page.has_no_xpath?('//*', :text => regexp)
  end
end

Then /^(?:|I )should be on (.+)$/ do |page_name|
  current_path = URI.parse(current_url).path
  if current_path.respond_to? :should
    current_path.should == path_to(page_name)
  else
    assert_equal path_to(page_name), current_path
  end
end

Then /^I should see (\d+) elements? kind of (.+)$/ do |count, locator|
  actual_count = all(selector_for(locator)).count
  count = count.to_i

  if actual_count.respond_to?(:should)
    actual_count.should eq(count)
  else
    assert_equal count, actual_count
  end
end

Then /^I should not see elements? kind of (.+)$/ do |locator|
  if defined?(RSpec)
    page.should_not have_css(selector_for(locator))
  else
    assert page.has_no_css?(selector_for(locator))
  end
end

# Use this to fill in an entire form with data from a table. Example:
#
#   When I fill in the following:
#     | Account Number                  | 5002       |
#     | Expiry date                     | 2009-11-01 |
#     | Note                            | Nice guy   |
#     | Wants Email?                    |            |
#     | Sex                  (select)   | Male       |
#     | Accept user agrement (checkbox) | check      |
#     | Send me letters      (checkbox) | uncheck    |
#     | radio 1              (radio)    | choose     |
#     | Avatar               (file)     | avatar.png |
#
When /^(?:|I )fill in the following:$/ do |fields|

  select_tag    = /^(.+\S+)\s*(?:\(select\))$/
  check_box_tag = /^(.+\S+)\s*(?:\(checkbox\))$/
  radio_button  = /^(.+\S+)\s*(?:\(radio\))$/
  file_field    = /^(.+\S+)\s*(?:\(file\))$/

  fields.rows_hash.each do |name, value|
    case name
    when select_tag
      step %(I select "#{value}" from "#{$1}")
    when check_box_tag
      case value
      when 'check'
  step %(I check "#{$1}")
      when 'uncheck'
  step %(I uncheck "#{$1}")
      else
  raise 'checkbox values: check|uncheck!'
      end
    when radio_button
      step %{I choose "#{$1}"}
    when file_field
      step %{I attach the file "#{value}" to "#{$1}"}
    else
      step %{I fill in "#{name}" with "#{value}"}
    end
  end
end

When /^(?:|I )fill in "([^"]*)" with "([^"]*)"$/ do |field, value|
  fill_in(field, :with => value)
end

When /^(?:|I )fill in "([^"]*)" with:$/ do |field, value|
  fill_in(field, :with => value)
end
When /^(?:|I )select "([^"]*)" from "([^"]*)"$/ do |value, field|
  select(value, :from => field)
end
When /^(?:|I )check "([^"]*)"$/ do |field|
  check(field)
end

When /^(?:|I )uncheck "([^"]*)"$/ do |field|
  uncheck(field)
end
When /^(?:|I )choose "([^"]*)"$/ do |field|
  choose(field)
end

When /^(?:|I )attach the file "([^"]*)" to "([^"]*)"$/ do |file, field|
  path = File.expand_path(File.join(SUPPORT_DIR,"attachments/#{file}"))
  raise RuntimeError, "file '#{path}' does not exists" unless File.exists?(path)

  attach_file(field, path)
end

Then /^the "([^"]*)" field(?: within (.*))? should contain "([^"]*)"$/ do |field, parent, value|
  with_scope(parent) do
    field = find_field(field)
    field_value = field.value
    if field_value.respond_to? :should
      field_value.should =~ /#{value}/
    else
      assert_match(/#{value}/, field_value)
    end
  end
end

Then /^the "([^"]*)" field(?: within (.*))? should not contain "([^"]*)"$/ do |field, parent, value|
  with_scope(parent) do
    field = find_field(field)
    field_value = field.value
    if field_value.respond_to? :should_not
      field_value.should_not =~ /#{value}/
    else
      assert_no_match(/#{value}/, field_value)
    end
  end
end

Then /^the "([^"]*)" checkbox(?: within (.*))? should be checked$/ do |label, parent|
  with_scope(parent) do
    field_checked = find_field(label)['checked']
    if field_checked.respond_to? :should
      field_checked.should be_true
    else
      assert field_checked
    end
  end
end
Then /^the "([^"]*)" checkbox(?: within (.*))? should not be checked$/ do |label, parent|
  with_scope(parent) do
    field_checked = find_field(label)['checked']
    if field_checked.respond_to? :should
      field_checked.should be_false
    else
      assert !field_checked
    end
  end
end

When /^(?:|I )press "([^"]*)"$/ do |button|
  click_button(button)
end
Then /^the select "([^"]*)" should have following options:$/ do |field, options|
  options = options.transpose.raw
  if options.size > 1
    raise 'table should have only one column in this step!'
  else
    options = options.first
  end

  actual_options = find_field(field).all('option').map { |option| option.text }

  if options.respond_to?(:should)
    options.should eq(actual_options)
  else
    assert_equal options, actual_options
  end
end

When /^(?:I|i) select following values from "([^"]*)":$/ do |field, values|
  values = values.transpose.raw
  if values.size > 1
    raise 'table should have only one column in this step!'
  else
    values = values.first
  end
  values.each do |value|
    select(value, :from => field)
  end
end
When /^(?:I|i) unselect following values from "([^"]*)":$/ do |field, values|
  values = values.transpose.raw
  if values.size > 1
    raise 'table should have only one column in this step!'
  else
    values = values.first
  end

  values.each do |value|
    unselect(value, :from => field)
  end
end

Then /^the following values should be selected in "([^"]*)":$/ do |select_box, values|
  values = values.transpose.raw
  if values.size > 1
    raise 'table should have only one column in this step!'
  else
    values = values.first
  end
  select_box=find_field(select_box)
  unless select_box['multiple']
    raise "this is not multiple select box!"
  else
    values.each do |value|
      if select_box.respond_to?(:should)
  select_box.value.should include(value)
      else
  assert select_box.value.include?(value)
      end
    end
  end
end
Then /^the following values should not be selected in "([^"]*)":$/ do |select_box, values|
  values = values.transpose.raw
  if values.size > 1
    raise 'table should have only one column in this step!'
  else
    values = values.first
  end

  select_box=find_field(select_box)
  unless select_box['multiple']
    raise "this is not multiple select box!"
  else
    values.each do |value|
      if select_box.respond_to?(:should)
  select_box.value.should_not include(value)
      else
  assert !select_box.value.include?(value)
      end
    end
  end
end

Then /^I debug$/ do
  debugger
end