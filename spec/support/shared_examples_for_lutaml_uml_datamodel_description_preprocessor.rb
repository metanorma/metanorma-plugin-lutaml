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

RSpec.shared_examples "should contain figure" do |figure|
  it "should contain figure" do
    figure.each do |id, name, src|
      expect(subject).to have_tag("figure"), with: { id: "figure-#{id}" }
      expect(subject).to have_tag("name"), text: /#{name}/
      expect(subject).to have_tag("image"), with: { src: src }
    end
  end
end

RSpec.shared_examples "should contain table" do |table|
  it "should contain table id and name" do
    table.each do |id, name|
      expect(subject).to have_tag("table"), with: { id: "table#section-#{id}" }
      expect(subject).to have_tag("table") do
        with_tag "name", text: /#{name}/
      end
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
  it "should contain table headers" do
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
      expect(subject).to have_tag("th"), with: { text: "#{th}:" }
    end
  end
end

RSpec.shared_examples "should contain xref objects" do |xref|
  it "should contain xref objects" do
    xref.each do |id, name|
      expect(subject).to have_tag("xref"), with: {
        target: "section-#{id}",
        text: /#{name}/,
      }
    end
  end
end

RSpec.shared_examples "should contain name, type, definition" do |i|
  it "should contain name, type, definition" do
    expect(subject).to have_tag("tr") do
      with_tag "td", text: i[:name]
      with_tag "td", text: i[:type]
      with_tag "td", text: i[:def] if i[:def]
    end
  end
end
