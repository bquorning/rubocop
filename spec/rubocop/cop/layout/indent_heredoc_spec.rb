# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Layout::IndentHeredoc, :config do
  subject(:cop) { described_class.new(config) }

  let(:allow_heredoc) { true }
  let(:other_cops) do
    {
      'Metrics/LineLength' => { 'Max' => 5, 'AllowHeredoc' => allow_heredoc }
    }
  end

  shared_examples 'offense' do |name, code, correction = nil|
    it "registers an offense for #{name}" do
      inspect_source(code.strip_indent)
      expect(cop.offenses.size).to eq(1)
    end

    it "autocorrects for #{name}" do
      corrected = autocorrect_source_with_loop(code.strip_indent)
      expect(corrected).to eq(correction)
    end
  end

  shared_examples 'all heredoc type' do |quote|
    context "quoted by #{quote}" do
      context 'EnforcedStyle is `powerpack`' do
        let(:cop_config) do
          { 'EnforcedStyle' => :powerpack }
        end

        include_examples 'offense', 'not indented', <<-RUBY, <<~CORRECTION
          <<#{quote}RUBY2#{quote}
          \#{foo}
          bar
          RUBY2
        RUBY
          <<#{quote}RUBY2#{quote}.strip_indent
            \#{foo}
            bar
          RUBY2
        CORRECTION
        include_examples 'offense', 'minus level indented',
                         <<-RUBY, <<~CORRECTION
          def foo
            <<#{quote}RUBY2#{quote}
          \#{foo}
          bar
          RUBY2
          end
        RUBY
          def foo
            <<#{quote}RUBY2#{quote}.strip_indent
              \#{foo}
              bar
          RUBY2
          end
        CORRECTION
        include_examples 'offense', 'not indented, with `-`',
                         <<-RUBY, <<~CORRECTION
          <<-#{quote}RUBY2#{quote}
          \#{foo}
          bar
          RUBY2
        RUBY
          <<-#{quote}RUBY2#{quote}.strip_indent
            \#{foo}
            bar
          RUBY2
        CORRECTION
        include_examples 'offense', 'minus level indented, with `-`',
                         <<-RUBY, <<~CORRECTION
          def foo
            <<-#{quote}RUBY2#{quote}
          \#{foo}
          bar
            RUBY2
          end
        RUBY
          def foo
            <<-#{quote}RUBY2#{quote}.strip_indent
              \#{foo}
              bar
            RUBY2
          end
        CORRECTION

        it 'does not register an offense when not indented but with ' \
           'whitespace, with `-`' do
          expect_no_offenses(<<-RUBY)
            def foo
              <<-#{quote}RUBY2#{quote}
              something
              RUBY2
            end
          RUBY
        end

        it 'accepts for indented, but with `-`' do
          expect_no_offenses <<~RUBY
            def foo
              <<-#{quote}RUBY2#{quote}
                something
              RUBY2
            end
          RUBY
        end

        it 'accepts for not indented but with whitespace' do
          expect_no_offenses <<~RUBY
            def foo
              <<#{quote}RUBY2#{quote}
              something
            RUBY2
            end
          RUBY
        end

        it 'accepts for indented, but without `~`' do
          expect_no_offenses <<~RUBY
            def foo
              <<#{quote}RUBY2#{quote}
                something
            RUBY2
            end
          RUBY
        end

        it 'accepts for an empty line' do
          expect_no_offenses <<~RUBY
            <<-#{quote}RUBY2#{quote}

            RUBY2
          RUBY
        end

        context 'when Metrics/LineLength is configured' do
          let(:allow_heredoc) { false }

          include_examples 'offense', 'short heredoc', <<-RUBY, <<~CORRECTION
            <<#{quote}RUBY2#{quote}
            12
            RUBY2
          RUBY
            <<#{quote}RUBY2#{quote}.strip_indent
              12
            RUBY2
          CORRECTION

          it 'accepts for long heredoc' do
            expect_no_offenses <<~RUBY
              <<#{quote}RUBY2#{quote}
              12345678
              RUBY2
            RUBY
          end
        end

        it 'displays a message with suggestion powerpack' do
          expect_offense(<<~RUBY)
            <<-RUBY2
            foo
            ^^^ Use 2 spaces for indentation in a heredoc by using `String#strip_indent`.
            RUBY2
          RUBY
        end
      end

      context 'EnforcedStyle is `squiggly`' do
        let(:cop_config) do
          { 'EnforcedStyle' => :squiggly }
        end

        include_examples 'offense', 'not indented', <<-RUBY, <<~CORRECTION
          <<~#{quote}RUBY2#{quote}
          something
          RUBY2
        RUBY
          <<~#{quote}RUBY2#{quote}
            something
          RUBY2
        CORRECTION
        include_examples 'offense', 'minus level indented',
                         <<-RUBY, <<~CORRECTION
          def foo
            <<~#{quote}RUBY2#{quote}
          something
            RUBY2
          end
        RUBY
          def foo
            <<~#{quote}RUBY2#{quote}
              something
            RUBY2
          end
        CORRECTION
        include_examples 'offense', 'too deep indented', <<-RUBY, <<~CORRECTION
          <<~#{quote}RUBY2#{quote}
              something
          RUBY2
        RUBY
          <<~#{quote}RUBY2#{quote}
            something
          RUBY2
        CORRECTION
        include_examples 'offense', 'not indented, without `~`',
                         <<-RUBY, <<~CORRECTION
          <<#{quote}RUBY2#{quote}
          foo
          RUBY2
        RUBY
          <<~#{quote}RUBY2#{quote}
            foo
          RUBY2
        CORRECTION

        include_examples 'offense', 'not indented, with `~`',
                         <<-RUBY, <<~CORRECTION
          <<~#{quote}RUBY2#{quote}
          foo
          RUBY2
        RUBY
          <<~#{quote}RUBY2#{quote}
            foo
          RUBY2
        CORRECTION

        include_examples 'offense', 'first line minus-level indented, with `-`',
                         <<-RUBY, <<-CORRECTION
                  puts <<-#{quote}RUBY2#{quote}
          def foo
            bar
          end
          RUBY2
        RUBY
        puts <<~#{quote}RUBY2#{quote}
          def foo
            bar
          end
        RUBY2
        CORRECTION

        it 'accepts for indented, with `~`' do
          expect_no_offenses <<~RUBY
            <<~#{quote}RUBY2#{quote}
              something
            RUBY2
          RUBY
        end

        it 'accepts for include empty lines' do
          expect_no_offenses <<~RUBY
            <<~#{quote}MSG#{quote}

              foo

                bar

            MSG
          RUBY
        end

        it 'displays message to use `<<~` instead of `<<`' do
          expect_offense(<<~RUBY)
            <<RUBY2
            foo
            ^^^ Use 2 spaces for indentation in a heredoc by using `<<~` instead of `<<`.
            RUBY2
          RUBY
        end

        it 'displays message to use `<<~` instead of `<<-`' do
          expect_offense(<<~RUBY)
            <<-RUBY2
            foo
            ^^^ Use 2 spaces for indentation in a heredoc by using `<<~` instead of `<<-`.
            RUBY2
          RUBY
        end
      end
    end
  end

  [nil, "'", '"', '`'].each do |quote|
    include_examples 'all heredoc type', quote
  end
end
