# encoding: utf-8
load File.expand_path( '../spec_helper.rb', File.dirname(__FILE__) )

require 'stringio'

RSpec::Matchers.define :have_attribute do | attribute |
  match do | object |
    if ! object.respond_to?( attribute )
      false
    elsif object.method( attribute ).arity != 0
      false
    else
      true
    end
  end
end

describe Metar::Station do

  before :each do
    @file = stub( 'file' )
  end

  context 'using structures' do

    before :each do
      Metar::Station.stub!(:open).with(Metar::Station::NOAA_STATION_LIST_URL).and_return(nsd_file)
    end

    context '.countries' do
      it 'lists unique countries in alphabetical order' do
        Metar::Station.countries. should     == [ 'Aaaaa', 'Bbbbb', 'Ppppp' ]
      end
    end

    context '.all' do
      it 'lists all stations' do
        all = Metar::Station.all

        all.map(&:cccc).          should     == ['PPPP', 'AAAA', 'AAAB', 'BBBA']
      end
    end

    context '.find_by_cccc' do
      it 'returns the matching station, if is exists' do
        Metar::Station.find_by_cccc( 'AAAA' ).name.
                                  should     == 'Airport A1'
        Metar::Station.find_by_cccc( 'ZZZZ' ).
                                  should     be_nil
      end
    end

    context '.exist?' do
      it 'check if the cccc code exists' do
        Metar::Station.exist?( 'AAAA' ).
                                  should     be_true
        Metar::Station.exist?( 'ZZZZ' ).
                                  should     be_false
      end
    end

    context '.find_all_by_country' do
      it 'lists all stations in a country' do
        aaaaa = Metar::Station.find_all_by_country( 'Aaaaa' )

        aaaaa.map(&:cccc).        should     == [ 'AAAA', 'AAAB' ]
      end
    end

    def nsd_file
#0    1  2   3    4     5       6 7        8         9        10        11  12  13
#CCCC;??;???;name;state;country;?;latitude;longitude;latitude;longitude;???;???;?
      nsd_text =<<EOT
PPPP;00;000;Airport P1;;Ppppp;1;11-03S;055-24E;11-03S;055-24E;000;000;P
AAAA;00;000;Airport A1;;Aaaaa;1;11-03S;055-24E;11-03S;055-24E;000;000;P
AAAB;00;000;Airport A2;;Aaaaa;1;11-03S;055-24E;11-03S;055-24E;000;000;P
BBBA;00;000;Airport B1;;Bbbbb;1;11-03S;055-24E;11-03S;055-24E;000;000;P
EOT
      StringIO.new( nsd_text )
    end

  end

  context '.to_longitude' do
    it 'converts strings to longitude' do
      Metar::Station.to_longitude('055-24E').
                                  should     == 55.4
    end
    it 'returns nil for badly formed strings' do
      Metar::Station.to_longitude('aaa').
                                  should     be_nil
    end
  end

  context '.to_latitude' do
    it 'converts strings to latitude' do
      Metar::Station.to_latitude('11-03S').
                                  should     == -11.05
    end
    it 'returns nil for badly formed strings' do
      Metar::Station.to_latitude('aaa').
                                  should     be_nil
    end
  end

  def noaa_data
    {
      :cccc      => 'DDDD',
      :name      => 'Station name',
      :state     => 'State',
      :country   => 'Country',
      :longitude => '055-24E',
      :latitude  => '11-03S',
      :raw       => 'DDDD;00;000;Station name;State;Country;1;11-03S;055-24E;11-03S;055-24E;000;000;P',
    }
  end

  context 'attributes' do
 
     subject { Metar::Station.new( 'DDDD', noaa_data ) }
     it { should have_attribute( :cccc )     }
     it { should have_attribute( :code )     }
     it { should have_attribute( :name )     }
     it { should have_attribute( :state )    }
     it { should have_attribute( :country )  }
     it { should have_attribute( :longitude) }
     it { should have_attribute( :latitude ) }
     it { should have_attribute( :raw )      }
 
  end
  
  context 'initialization' do
  
     it 'should fail if cccc is missing' do
       expect do
         Metar::Station.new( nil, {} )
       end.       to         raise_error( RuntimeError, /must not be nil/ )      
     end
  
     it 'should fail if cccc is empty' do
       expect do
         Metar::Station.new( '', {} )
       end.       to         raise_error( RuntimeError, /must not be empty/ )      
     end
   
    context 'with noaa data' do
    
      subject { Metar::Station.new( 'DDDD', noaa_data ) }
      specify { subject.cccc.      should     == 'DDDD' }
      specify { subject.name.      should     == 'Station name' }
      specify { subject.state.     should     == 'State' }
      specify { subject.country.   should     == 'Country' }
      specify { subject.longitude. should     == 55.4 }
      specify { subject.latitude.  should     == -11.05 }
      specify { subject.raw.       should     == 'DDDD;00;000;Station name;State;Country;1;11-03S;055-24E;11-03S;055-24E;000;000;P' }
    
    end

  end

  context 'object navigation' do
    before :each do
      @raw = stub('raw', :metar => 'PAIL 061610Z 24006KT 1 3/4SM -SN BKN016 OVC030 M17/M20 A2910 RMK AO2 P0000', :time => '2010/02/06 16:10' )
      # TODO: hack - once parser returns station this can be removed
      Metar::Raw::Noaa.           should_receive( :new ).
                                  and_return( @raw )
    end

    subject { Metar::Station.new( 'DDDD', noaa_data ) }

    it '.station should return the Parser' do
      subject.parser.             should     be_a Metar::Parser
    end

    it '.report should return the Report' do
      Metar::Station.             should_receive( :find_by_cccc ).
                                  and_return( subject )

      subject.report.             should     be_a Metar::Report
    end
  end

end

