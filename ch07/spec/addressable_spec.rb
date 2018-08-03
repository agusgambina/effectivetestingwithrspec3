require 'addressable'
require 'support/uri_shared_examples'

RSpec.describe Addressable do
  it_behaves_like 'URI', Addressable::URI  
end
