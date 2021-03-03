require "anpo"

RSpec.describe Anpo::PO do
  it "empty_test" do
  end

  it "basic" do
    po = Anpo::PO.parse(__dir__ + "/basic.po")
    expect(po.length).to eq 1
    expect(po[0].msgid).to eq "Page Setup..."
    expect(po[0].msgstr).to eq "ページ設定..."
    expect(po.msg["Page Setup..."]).to eq "ページ設定..."
  end

  it "newentry" do
    po = Anpo::PO.parse(__dir__ + "/basic.po")
    po.new_entry("xxx", "yyy")

    expect(po.msg["Page Setup..."]).to eq "ページ設定..."
    expect(po.msg["xxx"]).to eq "yyy"
  end

  it "change msgid" do
    po = Anpo::PO.parse(__dir__ + "/basic.po")
    expect(po.length).to eq 1
    expect(po.msg["Page Setup..."]).to eq "ページ設定..."

    po[0].msgid = "xxx"
    expect(po.msg["xxx"]).to eq "ページ設定..."
  end

  it "onchange" do
    po = Anpo::PO.parse(__dir__ + "/basic.po")

    check = false

    po[0].on_changed do |_x|
      check = true
    end

    po[0].msgstr = "xxx"
    expect(check).to eq true
  end

  it "filter_by_ids" do
    po = Anpo::PO.parse(__dir__ + "/entry2.po")
    po.filter_by_ids(["Page Setup..."])

    expect(po.length).to eq 1
    expect(po.msg["Page Setup..."]).to eq "ページ設定..."
  end

  it "delete_by_ids" do
    po = Anpo::PO.parse(__dir__ + "/entry2.po")
    po.delete_by_ids(["Page Setup..."])

    expect(po.length).to eq 1
    expect(po.msg["Notes"]).to eq "注釈"
  end
end
