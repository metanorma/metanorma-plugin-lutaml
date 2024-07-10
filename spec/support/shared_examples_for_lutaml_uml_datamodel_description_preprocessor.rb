RSpec.shared_examples "should contain preface" do
  it "should contain preface" do
    expect(subject).to have_tag("preface") do
      with_tag "foreword"
      with_tag "title", text: "Foreword"
      with_tag "p", text: /mine text/
    end
  end
end

RSpec.shared_examples "should contain sections" do
  it "should contain sections" do
    expect(subject).to have_tag("sections")
  end
end

RSpec.shared_examples "should contain footer text" do
  it "should contain footer text" do
    expect(subject).to have_tag("clause") do
      with_tag "p", text: /footer text/
    end
  end
end

RSpec.shared_examples "should contain text after package" do |title, content|
  it "should contain text after package" do
    expect(subject).to have_tag("clause") do
      with_tag "title", text: title
      with_tag "clause"
      with_tag "p", text: /#{content}/
    end
  end
end

RSpec.shared_examples "should contain package content" do |package_name|
  it "should contain package content" do
    expect(subject).to have_tag("clause") do
      with_tag "title", text: "#{package_name} package"
      with_tag "clause"
      with_tag "title", text: "#{package_name} overview"
    end
  end
end

RSpec.shared_examples "should contain clause title" do |clause_id, title|
  it "should contain clause title" do
    expect(subject).to have_tag("clause", with: { id: clause_id }) do
      with_tag "title", text: /#{title}/
    end
  end
end

RSpec.shared_examples "should contain text" do |text|
  it "should contain text" do
    expect(subject).to have_tag("p"), with: { text: /#{text}/ }
  end
end

RSpec.shared_examples "should contain figure" do |id, name, src|
  it "should contain figure" do
    expect(output).to have_tag("clause") do
      with_tag "figure#figure-#{id}"
      with_tag "name", text: /#{name}/
      with_tag "image", with: { src: src }
    end
  end
end

RSpec.shared_examples "should contain table" do |id, name|
  it "should contain table id" do
    expect(subject).to have_tag("table"), with: { id: "table#section-#{id}" }
  end

  it "should contain table name" do
    expect(subject).to have_tag("table") do
      with_tag "name", text: /#{name}/
    end
  end
end

RSpec.shared_examples "should contain table title" do
  it "should contain table title" do
    expect(subject).to have_tag("clause") do
      with_tag "title", text: "Defining tables"
    end
  end
end

RSpec.shared_examples "should contain table headers" do
  %w[
    Name
    Definition
    Stereotype
    Abstract
    Associations
    Public attributes
    Constraints
    Values
  ].each do |th|
    it "should contain table headers" do
      expect(subject).to have_tag("th"), with: { text: "#{th}:" }
    end
  end
end

RSpec.shared_examples "should contain xref objects" do |id, name|
  it "should contain xref objects" do
    expect(subject).to have_tag("xref"), with: {
      target: "section-#{id}",
      text: /#{name}/,
    }
  end
end
