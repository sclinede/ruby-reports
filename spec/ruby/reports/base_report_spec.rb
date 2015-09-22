# coding: utf-8
require 'spec_helper'
require 'stringio'

class MyTypeReport < Ruby::Reports::BaseReport
  def initialize(*args)
    super
    config.extension = :type
    config.storage = Ruby::Reports::Storages::HASH
  end

  def write(io, force = false)
    write_line io, table.build_header

    iterator.data_each(true) do |element|
      write_line io, table.build_row(element)
    end
  end

  def write_line(io, row)
    io << "#{row.nil? ? 'nil' : row.join('|')}\r\n"
  end
end

class MyReport < MyTypeReport
  config(
    queue: :my_type_reports,
    source: :select_data,
    encoding: 'utf-8',
    directory: File.join(Dir.tmpdir, 'ruby-reports')
  )

  table do |element|
    column 'First one', :one
    column 'Second', :two, formatter: :decorate_second
  end

  attr_reader :main_param

  def initialize(param)
    super
    @main_param = param
  end

  def self.decorate_second(text)
    "#{text} - is second"
  end

  def formatter
    self.class
  end

  def query
    @query ||= Query.new(self, config)
  end

  class Query < Ruby::Reports::Services::QueryBuilder
    def select_data
      [{one: 'one', two: 'one'}, {one: report.main_param, two: report.main_param}]
    end
  end
end

describe 'Ruby::Reports::BaseReport successor' do
  let(:io) { StringIO.new }
  let(:my_report) { MyReport.new('test') }
  let(:dummy) { Hash.new }

  describe '#extension' do
    before { my_report.build }

    it { expect(File.extname(my_report.filename)).to eq '.type' }
  end

  describe '#source' do
    before { allow(my_report.send(:query)).to receive(:select_data).and_return([dummy]) }

    it { expect(my_report.send(:query)).to receive(:select_data) }

    after { my_report.build true }
  end

  describe '#directory' do
    subject { my_report.send(:cache_file) }
    let(:tmpdir) { File.join(Dir.tmpdir, 'ruby-reports') }

    it { expect(subject.send(:dir)).to eq tmpdir }
  end

  describe '#create' do
    it { expect(my_report.send(:main_param)).to eq 'test' }
  end

  describe '#encoding' do
    subject { my_report.send :config }
    let(:utf_coding) { Ruby::Reports::UTF8 }

    it { expect(subject.encoding).to eq utf_coding }
  end

  describe '#write' do
    subject { MyReport.new('#write test') }

    before do
      allow(subject.send(:iterator)).to receive(:data_each) { |&block| block.call(dummy) }
      allow(subject.send(:table)).to receive(:build_row).and_return(['row'])
      allow(subject.send(:table)).to receive(:build_header).and_return(['header'])

      subject.write(io)
    end

    it { expect(io.string).to eq "header\r\nrow\r\n" }
  end

  describe '#build' do
    context 'when report decorated' do
      subject { MyReport.new('#build test') }

      it { expect(subject.formatter).to receive(:decorate_second).exactly(2).times }

      after  { subject.build true }
    end
    context 'when report was built' do
      subject { MyReport.new('was built test') }

      before { subject.build true }

      it { expect(subject).to be_exists }
      it do
        expect(File.read(subject.filename))
          .to eq <<-REPORT.gsub(/^ {12}/, '')
            First one|Second\r
            one|one - is second\r
            was built test|was built test - is second\r
          REPORT
      end
    end
  end

  describe '#data_each' do
    subject { MyReport.new('#data_each test') }

    it { expect(subject.send(:iterator)).to receive(:data_each) }

    after { subject.write(io) }
  end

  describe '#build_table_header' do
    subject { MyReport.new('#build_table_header test') }

    it { expect(subject.send(:table)).to receive(:build_header) }

    after { subject.write(io) }
  end

  describe '#build_table_row' do
    subject { MyReport.new('#build_table_row test') }

    it { expect(subject.send(:table)).to receive(:build_row).twice }

    after { subject.write(io) }
  end

end
