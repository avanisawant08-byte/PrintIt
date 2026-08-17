/**
 * Middleware to check if the user has a specific role.
 * Expects req.user to be populated by the auth middleware.
 * 
 * @param {string|string[]} allowedRoles - Role or array of roles allowed to access the route
 * @returns {Function} Middleware function
 */
const roleCheck = (allowedRoles) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({ error: 'Authentication required' });
        }

        const userRole = req.user.role;

        // If allowedRoles is a string, convert to array
        const roles = Array.isArray(allowedRoles) ? allowedRoles : [allowedRoles];

        if (!roles.includes(userRole)) {
            return res.status(403).json({ 
                error: 'Forbidden: You do not have permission to perform this action',
                required_role: allowedRoles
            });
        }

        next();
    };
};

module.exports = roleCheck;
