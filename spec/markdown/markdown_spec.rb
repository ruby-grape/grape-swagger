require 'spec_helper'

describe GrapeSwagger::Markdown do
  context 'initialization' do
    it 'initializes with an class that respond to markdown' do
      adapter = GrapeSwagger::Markdown::KramdownAdapter.new

      markdown = GrapeSwagger::Markdown.new adapter

      expect(markdown.adapter).to eq(adapter)
    end

    it 'raises an exception when the class does not respond to markdown' do
      expect { GrapeSwagger::Markdown.new(Class.new) }.to raise_error(ArgumentError, 'The configured markdown adapter should implement the method markdown')
    end
  end

  context 'as_markdown' do
    it 'calls markdown on the configured adapter' do
      text = '# Hello world #'
      adapter = GrapeSwagger::Markdown::KramdownAdapter.new
      expect(adapter).to receive(:markdown).with(text)

      GrapeSwagger::Markdown.new(adapter).as_markdown(text)
    end
  end
end
