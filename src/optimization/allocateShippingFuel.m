function countryFuel = allocateShippingFuel(routes, forwardFuel, reverseFuel, nCountry)
% Charge fuel to the actual origin, including when a route is reversed.
nRoutes = size(routes,1);
from = sparse(routes(:,1), (1:nRoutes)', ones(nRoutes,1), nCountry, nRoutes);
to = sparse(routes(:,2), (1:nRoutes)', ones(nRoutes,1), nCountry, nRoutes);
countryFuel = from * forwardFuel + to * reverseFuel;
end
