# frozen_string_literal: true

require 'spec_helper'

describe '#579 put / post parameters spec' do
  let(:app) do
    Class.new(Grape::API) do
      namespace :issue_579 do
        class BodySpec < Grape::Entity
          expose :guid, documentation: { type: String, format: 'guid', in: 'body' }
          expose :name, documentation: { type: String, in: 'body' }
          expose :content, documentation: { type: String, in: 'body' }
        end

        class Spec < Grape::Entity
          expose :guid, documentation: { type: String, format: 'guid' }
          expose :name, documentation: { type: String }
          expose :content, documentation: { type: String }
        end

        namespace :implicit do
          namespace :body_parameter do
            desc 'update spec',
                 success: BodySpec,
                 params: BodySpec.documentation
            put ':guid' do
              # your code goes here
            end
          end

          namespace :form_parameter do
            desc 'update spec',
                 success: Spec,
                 params: Spec.documentation
            put ':guid' do
              # your code goes here
            end
          end
        end

        namespace :explicit do
          namespace :body_parameter do
            desc 'update spec',
                 success: BodySpec,
                 params: BodySpec.documentation
            params do
              requires :guid
            end
            put ':guid' do
              # your code goes here
            end
          end

          namespace :form_parameter do
            desc 'update spec',
                 success: Spec,
                 params: Spec.documentation
            params do
              requires :guid
            end
            put ':guid' do
              # your code goes here
            end
          end
        end

        namespace :namespace_param do
          route_param :guid do
            namespace :body_parameter do
              desc 'update spec',
                   success: BodySpec,
                   params: BodySpec.documentation
              put do
                # your code goes here
              end
            end

            namespace :form_parameter do
              desc 'update spec',
                   success: Spec,
                   params: Spec.documentation
              put do
                # your code goes here
              end
            end
          end
        end
      end

      add_swagger_documentation format: :json
    end
  end

  subject do
    get '/swagger_doc'
    JSON.parse(last_response.body)
  end

  describe 'implicit path param given' do
    let(:body_parameters) { subject['paths']['/issue_579/implicit/body_parameter/{guid}']['put']['parameters'] }
    specify do
      expect(body_parameters).to eql(
        [
          { 'in' => 'path', 'name' => 'guid', 'type' => 'string', 'format' => 'guid', 'required' => true },
          {
            'name' => 'putIssue579ImplicitBodyParameterGuid', 'in' => 'body', 'required' => true, 'schema' => {
              '$ref' => '#/definitions/putIssue579ImplicitBodyParameterGuid'
            }
          }
        ]
      )
    end

    let(:form_parameters) { subject['paths']['/issue_579/implicit/form_parameter/{guid}']['put']['parameters'] }
    specify do
      expect(form_parameters).to eql(
        [
          { 'in' => 'path', 'name' => 'guid', 'type' => 'string', 'format' => 'guid', 'required' => true },
          { 'in' => 'formData', 'name' => 'name', 'type' => 'string', 'required' => false },
          { 'in' => 'formData', 'name' => 'content', 'type' => 'string', 'required' => false }
        ]
      )
    end
  end

  describe 'explicit path param given' do
    let(:body_parameters) { subject['paths']['/issue_579/explicit/body_parameter/{guid}']['put']['parameters'] }
    specify do
      expect(body_parameters).to eql(
        [
          { 'in' => 'path', 'name' => 'guid', 'type' => 'string', 'format' => 'guid', 'required' => true },
          {
            'name' => 'putIssue579ExplicitBodyParameterGuid', 'in' => 'body', 'required' => true, 'schema' => {
              '$ref' => '#/definitions/putIssue579ExplicitBodyParameterGuid'
            }
          }
        ]
      )
    end

    let(:form_parameters) { subject['paths']['/issue_579/explicit/form_parameter/{guid}']['put']['parameters'] }
    specify do
      expect(form_parameters).to eql(
        [
          { 'in' => 'path', 'name' => 'guid', 'type' => 'string', 'format' => 'guid', 'required' => true },
          { 'in' => 'formData', 'name' => 'name', 'type' => 'string', 'required' => false },
          { 'in' => 'formData', 'name' => 'content', 'type' => 'string', 'required' => false }
        ]
      )
    end
  end

  describe 'explicit as route param given' do
    let(:body_parameters) { subject['paths']['/issue_579/namespace_param/{guid}/body_parameter']['put']['parameters'] }
    specify do
      expect(body_parameters).to eql(
        [
          { 'in' => 'path', 'name' => 'guid', 'type' => 'string', 'format' => 'guid', 'required' => true },
          {
            'name' => 'putIssue579NamespaceParamGuidBodyParameter', 'in' => 'body', 'required' => true, 'schema' => {
              '$ref' => '#/definitions/putIssue579NamespaceParamGuidBodyParameter'
            }
          }
        ]
      )
    end

    let(:form_parameters) { subject['paths']['/issue_579/namespace_param/{guid}/form_parameter']['put']['parameters'] }
    specify do
      expect(form_parameters).to eql(
        [
          { 'in' => 'path', 'name' => 'guid', 'type' => 'string', 'format' => 'guid', 'required' => true },
          { 'in' => 'formData', 'name' => 'name', 'type' => 'string', 'required' => false },
          { 'in' => 'formData', 'name' => 'content', 'type' => 'string', 'required' => false }
        ]
      )
    end
  end
end
