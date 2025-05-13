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

RSpec.shared_examples "should contain clause title" do |clause_title|
  it "should contain clause title" do
    clause_title.each do |ct|
      expect(subject).to have_tag("clause", with: { anchor: ct[:clause_id] }) do
        with_tag "title", text: /#{ct[:title]}/
      end
    end
  end
end

RSpec.shared_examples "should contain text" do |text|
  it "should contain text" do
    expect(subject).to have_tag("p", text: /#{text}/)
  end
end

RSpec.shared_examples "should contain figure" do |figures|
  it "should contain figure" do
    figures.each do |figure|
      expect(subject).to have_tag("figure",
                                  with: { anchor: "figure-#{figure[:id]}" })
      expect(subject).to have_tag("name", text: /#{figure[:name]}/)
      expect(subject).to have_tag("image", with: { src: figure[:src] })
    end
  end
end

RSpec.shared_examples "should contain table" do |table|
  it "should contain table name" do
    table.each do |i|
      expect(subject).to have_tag("table") do
        with_tag "name", text: /#{i[:name]}/
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
      expect(subject).to have_tag("th", text: /#{th}/)
    end
  end
end

RSpec.shared_examples "should contain properties related headers" do |headers|
  it "should contain properties related headers" do
    headers.each do |th|
      expect(subject).to have_tag("th", text: /#{th}/)
    end
  end
end

RSpec.shared_examples "should contain xref objects" do |xrefs|
  it "should contain xref objects" do
    xrefs.each do |xref|
      expect(subject).to have_tag(
        "xref",
        with: {
          target: "section-#{xref[:id]}",
        },
        text: xref[:name],
      )
    end
  end
end

RSpec.shared_examples "should contain name, type, definition" do |name_type_def|
  it "should contain name, type, definition" do
    name_type_def.each do |i|
      expect(subject).to have_tag("tr") do
        with_tag "td", text: /#{i[:name]}/
        with_tag "td", text: i[:type]
        with_tag "td", text: i[:def] if i[:def]
      end
    end
  end
end

RSpec.shared_examples "should contain Used and Guidance" do
  it "should contain Used and Guidance" do
    [
      {
        name: "gml:boundedBy",
        type: "gml::Envelope [0..1]",
        desc: "建築物の範囲及び適用される空間参照系。",
        used: "false",
        guidance: "この属性は使用されていません。",
      },
      {
        name: "gml:description",
        type: "gml::StringOrRefType [0..1]",
        desc: "土地利用の概要。",
        used: "true",
        guidance: "",
      },
    ].each do |i|
      expect(subject).to have_tag("tr") do
        with_tag "td", text: /#{i[:name]}/
        with_tag "td", text: i[:type]
        with_tag "td", text: i[:desc]
        with_tag "td", text: i[:used]
        with_tag "td", text: i[:guidance]
      end
    end
  end
end
