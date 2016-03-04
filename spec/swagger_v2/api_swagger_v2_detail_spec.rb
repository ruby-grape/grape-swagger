# encoding: UTF-8

require 'spec_helper'

def details
<<-DETAILS
# Burgers in Heaven

> A burger doesn't come for free

If you want to reserve a burger in heaven, you have to do
some crazy stuff on earth.

```
def do_good
puts 'help people'
end
```

* _Will go to Heaven:_ Probably
* _Will go to Hell:_ Probably not
DETAILS
end

describe 'details' do
  describe "take deatils as it is" do
    include_context "the api entities"

    before :all do
      module TheApi
        class DetailApi < Grape::API
          format :json

          desc 'This returns something',
            detail: 'detailed description of the route',
            entity: Entities::UseResponse,
            failure: [{code: 400, model: Entities::ApiError}]
          get '/use_detail' do
            { "declared_params" => declared(params) }
          end

          desc 'This returns something' do
            detail 'detailed description of the route inside the `desc` block'
            entity Entities::UseResponse
            failure [{code: 400, model: Entities::ApiError}]
          end
          get '/use_detail_block' do
            { "declared_params" => declared(params) }
          end

          add_swagger_documentation
        end
      end
    end

    def app
      TheApi::DetailApi
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/use_detail']['get']).to include('description')
      expect(subject['paths']['/use_detail']['get']['description']).to eql 'detailed description of the route'
    end

    specify do
      expect(subject['paths']['/use_detail_block']['get']).to include('description')
      expect(subject['paths']['/use_detail_block']['get']['description']).to eql 'detailed description of the route inside the `desc` block'
    end
  end

  describe 'details, convert markdown with kramdown' do
    include_context "the api entities"

    before :all do
      module TheApi
        class GfmDetailApi < Grape::API
          format :json

          desc 'This returns something',
            detail: details,
            entity: Entities::UseResponse,
            failure: [{code: 400, model: Entities::ApiError}]
          get '/use_gfm_detail' do
            { "declared_params" => declared(params) }
          end

          add_swagger_documentation markdown: GrapeSwagger::Markdown::KramdownAdapter.new
        end
      end
    end

    def app
      TheApi::GfmDetailApi
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/use_gfm_detail']['get']).to include('description')
      expect(subject['paths']['/use_gfm_detail']['get']['description']).to eql(
        "<h1 id=\"burgers-in-heaven\">Burgers in Heaven</h1>\n\n<blockquote>\n  <p>A burger doesn’t come for free</p>\n</blockquote>\n\n<p>If you want to reserve a burger in heaven, you have to do<br />\nsome crazy stuff on earth.</p>\n\n<pre><code>def do_good\nputs 'help people'\nend\n</code></pre>\n\n<ul>\n  <li><em>Will go to Heaven:</em> Probably</li>\n  <li><em>Will go to Hell:</em> Probably not</li>\n</ul>"
      )
    end
  end

  describe 'details, convert markdown with redcarpet', unless: RUBY_PLATFORM.eql?('java') do
    include_context "the api entities"

    before :all do
      module TheApi
        class GfmRcDetailApi < Grape::API
          format :json

          desc 'This returns something',
            detail: details,
            entity: Entities::UseResponse,
            failure: [{code: 400, model: Entities::ApiError}]
          get '/use_gfm_rc_detail' do
            { "declared_params" => declared(params) }
          end

          add_swagger_documentation markdown: GrapeSwagger::Markdown::RedcarpetAdapter.new
        end
      end
    end

    def app
      TheApi::GfmRcDetailApi
    end

    subject do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    specify do
      expect(subject['paths']['/use_gfm_rc_detail']['get']).to include('description')
      expect(subject['paths']['/use_gfm_rc_detail']['get']['description']).to eql(
        "<h1>Burgers in Heaven</h1>\n\n<blockquote>\n<p>A burger doesn&#39;t come for free</p>\n</blockquote>\n\n<p>If you want to reserve a burger in heaven, you have to do\nsome crazy stuff on earth.</p>\n<pre class=\"highlight plaintext\"><code>def do_good\nputs 'help people'\nend\n</code></pre>\n\n<ul>\n<li><em>Will go to Heaven:</em> Probably</li>\n<li><em>Will go to Hell:</em> Probably not</li>\n</ul>"
      )
    end
  end
end
