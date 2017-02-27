require 'spec_helper'

describe GrapeSwagger::DocMethods::TagNameDescription do
  describe '#build_memo' do
    let(:tag) { 'some_string' }
    subject { described_class.send(:build_memo, tag) }

    specify do
      expect(subject.keys).to eql [:name, :description]
      expect(subject).to eql(
        name: tag,
        description: "Operations about #{tag.pluralize}"
      )
    end
  end

  describe '#build' do
    let(:object) { described_class.build(paths) }

    describe 'empty paths' do
      let(:paths) { {} }
      specify do
        expect(object).to eql([])
      end
    end

    describe 'paths given' do
      describe 'uniq as String' do
        let(:paths) do
          { key_1: { post: { tags: 'tags_given' } } }
        end

        specify do
          expect(object).to eql [{ name: 'tags_given', description: 'Operations about tags_givens' }]
        end
      end

      describe 'uniq as Array' do
        let(:paths) do
          { key_1: { post: { tags: ['tags_given'] } } }
        end

        specify do
          expect(object).to eql [{ name: 'tags_given', description: 'Operations about tags_givens' }]
        end
      end

      describe 'multiple' do
        describe 'uniq key' do
          let(:paths) do
            {
              key_1: { post: { tags: %w(tags_given another_tag_given) } }
            }
          end

          specify do
            expect(object).to eql [
              { name: 'tags_given', description: 'Operations about tags_givens' },
              { name: 'another_tag_given', description: 'Operations about another_tag_givens' }
            ]
          end
        end
        describe 'under different keys' do
          let(:paths) do
            {
              key_1: { post: { tags: ['tags_given'] } },
              key_2: { post: { tags: ['tags_given'] } }
            }
          end

          specify do
            expect(object).to eql [{ name: 'tags_given', description: 'Operations about tags_givens' }]
          end
        end
      end
    end
  end
end
