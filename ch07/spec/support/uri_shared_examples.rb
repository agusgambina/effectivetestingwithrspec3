RSpec.shared_examples 'URI' do |uri|
  let(:uri) { uri.new }

  it 'parses the host' do
    expect(uri.parse('http://foo.com/').host).to eq 'foo.com'
  end
  
  it 'parses the port' do
    expect(uri.parse('http://example.com:9876').port).to eq 9876
  end
  
  it 'defaults the port for an http URI to 80' do
    expect(uri.parse('http://example.com/').port).to eq 80
  end

  it 'defaults the port for an https URI to 443' do
    expect(uri.parse('https://example.com/').port).to eq 443
  end

  it 'parses the scheme' do
    expect(uri.parse('https://a.com/').scheme).to eq 'https'
  end
  
  it 'parses the host' do
  expect(uri.parse('https://foo.com/').host).to eq 'foo.com'
  end

  it 'parses the port' do
    expect(uri.parse('http://example.com:9876').port).to eq 9876
  end

  it 'parses the path' do
    expect(uri.parse('http://a.com/foo').path).to eq '/foo'
  end
  
end