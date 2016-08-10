using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(SearchEngine.Startup))]
namespace SearchEngine
{
    public partial class Startup {
        public void Configuration(IAppBuilder app) {
            ConfigureAuth(app);
        }
    }
}
