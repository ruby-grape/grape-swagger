require 'spec_helper'

describe GrapeSwagger::Markdown::KramdownAdapter do
  context 'initialization' do
    it 'uses GFM as default input and disable coderay' do
      adapter = GrapeSwagger::Markdown::KramdownAdapter.new

      expect(adapter.options).to eq(input: 'GFM', enable_coderay: false)
    end

    it 'overrides default values' do
      options = { input: 'kramdown', enable_coderay: true }

      adapter = GrapeSwagger::Markdown::KramdownAdapter.new options

      expect(adapter.options).to eq(options)
    end
  end

  context 'markdown' do
    it 'marks down with the configured options' do
      text = '# hello world'
      options = { input: 'GFM', enable_coderay: true, auto_ids: false, hard_wrap: true }
      expect(GrapeSwagger::Markdown::KramdownAdapter).to receive(:new).with(options).and_call_original

      output = GrapeSwagger::Markdown::KramdownAdapter.new(options).markdown(text)

      expect(output).to include('<h1>hello world</h1>')
    end
  end
end
