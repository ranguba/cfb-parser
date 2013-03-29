# Copyright (C) 2013  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library.  If not, see
# <http://www.gnu.org/licenses/>.

class TestParser < Test::Unit::TestCase
  private
  def fixture_directory
    File.join(File.dirname(__FILE__), "fixture")
  end

  def fixture_path(*components)
    File.join(fixture_directory, *components)
  end

  class TestHeader < self
    def setup
      @file = File.open(fixture_path("empty.ppt"))
      @parser = CFB::Parser.new(@file)
      @parser.parse
    end

    def test_major_version
      assert_equal(3, @parser.major_version)
    end

    def test_minor_version
      assert_equal(0x003b, @parser.minor_version)
    end

    def test_section_size
      assert_equal(2 ** 9, @parser.sector_size)
    end

    def test_mini_section_size
      assert_equal(2 ** 6, @parser.mini_sector_size)
    end

    def test_n_directory_sectors
      assert_equal(0, @parser.n_directory_sectors)
    end
  end
end
