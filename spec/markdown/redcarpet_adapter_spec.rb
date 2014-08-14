require 'spec_helper'

describe GrapeSwagger::Markdown::RedcarpetAdapter, unless: RUBY_PLATFORM.eql?('java') do

  context 'initialization' do
    context 'initialization' do
      it 'uses fenced_code_blocks, auto_links and rouge as default.' do
        expect_any_instance_of(GrapeSwagger::Markdown::RedcarpetAdapter).to receive(:new_redcarpet_renderer).with(:rouge).and_call_original

        adapter = GrapeSwagger::Markdown::RedcarpetAdapter.new

        expect(adapter.extension_options).to eq(fenced_code_blocks: true, autolink: true)
        expect(adapter.render_options).to eq({})
      end

      it 'initializes with no highlighter.' do
        expect_any_instance_of(GrapeSwagger::Markdown::RedcarpetAdapter).to receive(:new_redcarpet_renderer).with(:none).and_call_original

        adapter = GrapeSwagger::Markdown::RedcarpetAdapter.new render_options: { highlighter: :none }

        expect(adapter.extension_options).to eq(fenced_code_blocks: true, autolink: true)
        expect(adapter.render_options).to eq({})
      end

      it 'overrides default values' do
        extensions = { fenced_code_blocks: true, autolink: true }
        render_options = { highlighter: :none, no_links: true }

        adapter = GrapeSwagger::Markdown::RedcarpetAdapter.new extensions: extensions, render_options: render_options

        expect(adapter.extension_options).to eq(extensions)
        expect(adapter.render_options).to eq(no_links: true)
      end

      it 'raises an GrapeSwagger::Errors::MarkdownDependencyMissingError if module can not be required.' do
        expect_any_instance_of(Kernel).to receive(:require).with('redcarpet').and_raise(LoadError)

        expect { GrapeSwagger::Markdown::RedcarpetAdapter.new }.to raise_error(GrapeSwagger::Errors::MarkdownDependencyMissingError, 'Missing required dependency: redcarpet')
      end
    end

    context 'markdown' do
      it 'marks down with the configured options' do
        text = '# hello world #'
        extensions = { fenced_code_blocks: true, autolink: true }
        render_options = { highlighter: :none, no_links: true, highlighter: :none }
        expect_any_instance_of(Redcarpet::Markdown).to receive(:render).with(text).and_call_original

        output = GrapeSwagger::Markdown::RedcarpetAdapter.new(extensions: extensions, render_options: render_options).markdown(text)

        expect(output).to include('<h1>hello world</h1>')
      end
    end

    context 'new_redcarpet_renderer' do
      it 'returns a rouge syntax highlighter' do
        adapter = GrapeSwagger::Markdown::RedcarpetAdapter.new
        renderer = adapter.send(:new_redcarpet_renderer, :rouge)

        expect(renderer).to include(Rouge::Plugins::Redcarpet)
        expect(renderer.superclass).to be(Redcarpet::Render::HTML)
      end

      it 'throws an error when rouge syntax highlighter cant be included' do
        adapter = GrapeSwagger::Markdown::RedcarpetAdapter.new

        expect_any_instance_of(Kernel).to receive(:require).with('rouge').and_raise(LoadError)

        expect { adapter.send(:new_redcarpet_renderer, :rouge) }.to raise_error(GrapeSwagger::Errors::MarkdownDependencyMissingError, 'Missing required dependency: rouge')
      end

      it 'returns a default syntax highlighter' do
        adapter = GrapeSwagger::Markdown::RedcarpetAdapter.new
        renderer = adapter.send(:new_redcarpet_renderer, :none)

        expect(renderer).to include(GrapeSwagger::Markdown::RedcarpetAdapter::RenderWithoutSyntaxHighlighter)
        expect(renderer.superclass).to be(Redcarpet::Render::HTML)
      end
    end
  end
end
