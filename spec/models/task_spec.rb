# == Schema Information
#
# Table name: tasks
#
#  id         :integer          not null, primary key
#  title      :string
#  done       :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe Task, type: :model do
  context "Validations" do 
    it "validates title" do 
      expect(subject.title).to be_nil
      expect(subject).not_to be_valid
      subject.title = "My Awesome title"
      expect(subject.title).not_to be_nil
      expect(subject).to be_valid
    end
  end
end
