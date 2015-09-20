# coding: utf-8
require 'spec_helper'
require 'stringio'

require 'ruby/reports/csv_report'

class MyCsvReport < Ruby::Reports::CsvReport
  config(
    queue: :csv_reports,
    source: :select_data,
    encoding: 'utf-8',
    csv_options: {col_sep: ',', row_sep: "\n"},
    directory: File.join(Dir.home, '.ruby-reports')
  )

  table do |row|
    column 'First one', decorate_first(row[:first])
    column 'Second', "#{row[:second]} - is second"
    column 'Third', :third, formatter: :cute_third
  end

  attr_reader :main_param
  def initialize(param)
    super
    @main_param = param
  end

  def self.decorate_first(element)
    "decorated: #{element}"
  end

  def formatter
    @formatter ||= Formatter.new
  end

  def query
    @query ||= Query.new(self)
  end

  class Formatter
    def cute_third(column_value)
      "3'rd row element is: #{column_value}"
    end
  end

  class Query
    pattr_initialize :report
    def select_data
      [{:first => :one, :second => report.main_param, :third => 3}]
    end
  end
end

class MyCsvDefaultsReport < Ruby::Reports::CsvReport
  config(
    source: :select_data,
    encoding: 'utf-8',
    directory: File.join(Dir.tmpdir, 'ruby-reports')
  )

  table do |element|
    column 'Uno', "#{element} - is value"
  end

  def query
    Query.new
  end

  class Query
    def select_data
      []
    end
  end
end

class MyCsvExpiredReport < Ruby::Reports::CsvReport
  config(
    expire_in: 3600,
    source: :select_data,
    encoding: 'utf-8',
    directory: File.join(Dir.tmpdir, 'ruby-reports')
  )

  table do |element|
    column 'Uno', "#{element} - is value"
  end

  def query
    Query.new
  end

  class Query
    def select_data
      []
    end
  end
end

describe 'Ruby::Reports::CsvReport successor' do
  describe '.csv_options' do
    context 'when custom options not set' do
      subject { MyCsvDefaultsReport.new }

      it 'sets csv_options defaults' do
        expect(subject.csv_options).to eq Ruby::Reports::Config::DEFAULT_CSV_OPTIONS
      end
    end

    context 'when custom options are set' do
      subject { MyCsvReport.new('csv_options test') }

      let(:my_options) do
        Ruby::Reports::Config::DEFAULT_CSV_OPTIONS.merge(col_sep: ',', row_sep: "\n")
      end

      it 'merges csv_options with defaults' do
        expect(subject.csv_options).to eq my_options
      end
    end
  end

  describe '#build' do
    context 'when report was built' do
      subject { MyCsvReport.new('was built test') }

      after { subject.build true }

      it { expect(subject).to be_exists }
      it do
        expect(File.read(subject.filename))
          .to eq <<-CSV.gsub(/^ {12}/, '')
            First one,Second,Third
            decorated: one,was built test - is second,3'rd row element is: 3
          CSV
      end
    end
  end

  describe '#exists?' do
    context 'when report was built' do
      subject { MyCsvExpiredReport.new }

      before do
        subject.build(true)
      end

      it do
        Timecop.travel(Time.now + 3600) do
          expect(subject.exists?).to be_falsey
        end
      end

      it do
        Timecop.travel(Time.now + 1800) do
          expect(subject.exists?).to be_truthy
        end
      end
    end
  end
end
