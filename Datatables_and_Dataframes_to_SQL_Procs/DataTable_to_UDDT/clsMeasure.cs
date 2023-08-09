using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SQLSatDataTableDemo
{
    public class clsMeasure
    {
        private string _measureName;
        private int _value;

        public string MeasureName
        {
            get { return _measureName; }
        }

        public int Value
        {
            get { return _value; }
        }

        public clsMeasure(string measureName, int value)
        {
            _measureName = measureName;
            _value = value;
        }
    }
}
