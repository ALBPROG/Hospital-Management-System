# frozen_string_literal: true

shared_examples "parseable arguments" do
  subject(:method_name) do |example|
    example.metadata[:example_group][:parent_example_group][:description]
           .delete_prefix("Homebrew.")
  end

  let(:command_name) do
    method_name.delete_suffix("_args")
               .tr("_", "-")
  end

  it "can parse arguments" do
    require "dev-cmd/#{command_name}" unless require? "cmd/#{command_name}"

    expect { Homebrew.send(method_name).parse({}, allow_no_named_args: true) }
      .not_to raise_error
  end
end
