using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using SalesWeb.Models;

namespace SalesWeb.Controllers
{
	public class DepartmentsController : Controller
	{
		public IActionResult Index()
		{
			List<Department> list = new List<Department>();
			list.Add(new Department(1, "Eletronics"));
			list.Add(new Department(2, "Fashion"));

			return View(list);
		}
	}
}
