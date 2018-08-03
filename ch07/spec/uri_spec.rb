require 'uri'
require 'support/uri_shared_examples'

RSpec.describe Addressable do
  it_behaves_like 'URI', URI

  it 'defaults the port for an http URI to 80' do
    expect(URI.parse('http://example.com/').port).to eq 80
  end

  it 'defaults the port for an https URI to 443' do
    expect(URI.parse('https://example.com/').port).to eq 443
  end
  
end
