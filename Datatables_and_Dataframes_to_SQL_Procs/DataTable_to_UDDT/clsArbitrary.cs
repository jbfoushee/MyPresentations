using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.NetworkInformation;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;

namespace SQLSatDataTableDemo
{
    class clsArbitrary
    {
        public interface IPublicInterface
        { }

        private interface IPrivateInterface
        { }

        internal interface IInternalInterface
        { }

        protected interface IProtectedInterface
        { }

        protected internal interface IProtectedInternalInterface
        { }


        static int static_prop
        {
            get { return 3; }
        }

        private static int private_static_prop
        {
            get { return 3; }
        }

        public static int public_static_prop
        {
            get { return 3; }
        }

        public String public_prop
        {
            get { return "hello"; }
        }

        protected String protected_prop
        {
            get { return "hello"; }
        }

        private Int32 private_prop
        {
            get { return 32; }
        }

        internal String internal_prop
        {
            get { return "value"; }
        }

        protected internal String protectedinternal_prop
        {
            get { return "value"; }
        }
    }
}
