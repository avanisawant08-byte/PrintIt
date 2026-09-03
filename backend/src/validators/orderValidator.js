const Joi = require('joi');

const orderSchema = Joi.object({
    customer_id: Joi.string().uuid().required(),
    shop_id: Joi.string().uuid().required(),

    files: Joi.array().items(
        Joi.object({
            s3_key: Joi.string().required(),
            page_count: Joi.number().integer().min(1).required()
        })
    ).min(1).required(),

    print_options: Joi.object({
        color: Joi.string().valid('bw', 'color').required(),
        size: Joi.string().valid('A4', 'A3', 'Letter').required(),
        sides: Joi.string().valid('single', 'double').required(),
        copies: Joi.number().integer().min(1).required(),
        binding: Joi.string().valid('none', 'staple', 'spiral').required(),
        pages_per_paper: Joi.number().integer().valid(1, 2, 4, 6, 9, 16).default(1),
        orientation: Joi.string().valid('portrait', 'landscape').default('portrait')
    }).required(),

    amount_total: Joi.number().positive().precision(2).required(),
    stripe_payment_id: Joi.string().optional(),
    payment_id: Joi.string().optional(),
    razorpay_payment_id: Joi.string().optional(),
    print_instructions: Joi.string().max(500).allow('', null).optional()
});

module.exports = orderSchema;