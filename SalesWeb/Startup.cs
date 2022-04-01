using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.HttpsPolicy;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Localization;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Linq;
using System.Globalization;
using System.Threading.Tasks;
using System.Collections.Generic;
using SalesWeb.Data;
using SalesWeb.Services;

namespace SalesWeb
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.Configure<CookiePolicyOptions>(options =>
            {
                // This lambda determines whether user consent for non-essential cookies is needed for a given request.
                options.CheckConsentNeeded = context => true;
                options.MinimumSameSitePolicy = SameSiteMode.None;
            });


            services.AddMvc().SetCompatibilityVersion(CompatibilityVersion.Version_2_1);

            services.AddDbContext<SalesWebContext>(options =>
                    options.UseMySql(Configuration.GetConnectionString("SalesWebContext"), builder =>
                        builder.MigrationsAssembly("SalesWeb")));

            services.AddScoped<SeedingService>();
            services.AddScoped<SellerService>();
            services.AddScoped<DepartmentService>();
            services.AddScoped<SalesRecordService>();
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IHostingEnvironment env, SeedingService seedingService)
        {
            app.Use(async (context, next) =>
            {
                if (!context.Response.Headers.ContainsKey("X-Frame-Options"))
                    context.Response.Headers.Add("X-Frame-Options", "DENY");

                if (!context.Response.Headers.ContainsKey("X-Xss-Protection"))
                    context.Response.Headers.Add("X-Xss-Protection", "1; mode=block");

                if (!context.Response.Headers.ContainsKey("X-Content-Type-Options"))
                    context.Response.Headers.Add("X-Content-Type-Options", "nosniff");

                if (!context.Response.Headers.ContainsKey("Referrer-Policy"))
                    context.Response.Headers.Add("Referrer-Policy", "no-referrer");

                if (!context.Response.Headers.ContainsKey("X-Permitted-Cross-Domain-Policies"))
                    context.Response.Headers.Add("X-Permitted-Cross-Domain-Policies", "none");

                if (!context.Response.Headers.ContainsKey("Permissions-Policy"))
                    context.Response.Headers.Add("Permissions-Policy", "accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()");

                if (!context.Response.Headers.ContainsKey("Content-Security-Policy"))
                    context.Response.Headers.Add("Content-Security-Policy", "default-src 'self'");
                
                if (!context.Response.Headers.ContainsKey("Strict-Transport-Security"))
                    context.Response.Headers.Add("Strict-Transport-Security", "max-age=31536000; includeSubDomains");

                if (!context.Response.Headers.ContainsKey("Cross-Origin-Embedder-Policy"))
                    context.Response.Headers.Add("Cross-Origin-Embedder-Policy", "require-corp");

                if (!context.Response.Headers.ContainsKey("Cross-Origin-Resource-Policy"))
                    context.Response.Headers.Add("Cross-Origin-Resource-Policy", "same-site");

                if (!context.Response.Headers.ContainsKey("Cross-Origin-Opener-Policy"))
                    context.Response.Headers.Add("Cross-Origin-Opener-Policy", "same-origin");

                if (!context.Response.Headers.ContainsKey("Expect-CT"))
                    context.Response.Headers.Add("Expect-CT", "max-age=31536000");

                await next();
            });

            CultureInfo enUS = new CultureInfo("en-US");
            RequestLocalizationOptions localizationOptions = new RequestLocalizationOptions
            {
                DefaultRequestCulture = new RequestCulture(enUS),
                SupportedCultures = new List<CultureInfo> { enUS },
                SupportedUICultures = new List<CultureInfo> { enUS }

            };

            app.UseRequestLocalization(localizationOptions);

            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
                seedingService.Seed();
            }
            else
            {
                app.UseExceptionHandler("/Home/Error");
                app.UseHsts();
            }

            app.UseHttpsRedirection();
            app.UseStaticFiles();
            app.UseCookiePolicy();

            app.UseMvc(routes =>
            {
                routes.MapRoute(
                    name: "default",
                    template: "{controller=Home}/{action=Index}/{id?}");
            });
        }
    }
}
